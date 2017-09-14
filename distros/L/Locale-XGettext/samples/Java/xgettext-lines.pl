#! /usr/bin/env perl

use strict;

use File::Spec;

my $xgettext;

my $code;

BEGIN {
    my @spec = File::Spec->splitpath(__FILE__);
    $spec[2] = 'JavaXGettext.java';
    my $java_filename = File::Spec->catpath(@spec);
    open HANDLE, "<$java_filename"
        or die "Cannot open '$java_filename': $!\n";
    $code = join '', <HANDLE>;
}

use Inline Java => $code;

Locale::XGettext::Language::Java->newFromArgv(\@ARGV)->run->output;

package Locale::XGettext::Language::Java;

use strict;

use base 'Locale::XGettext';

sub newFromArgv {
    my ($class, @args) = @_;

    my $self = $xgettext = {};
    bless $self, $class;

    $self->{__helper} = JavaXGettext->new;

    $self->SUPER::newFromArgv(@args);

    return $self;
}

sub readFile {
    my ($self, $filename) = @_;

    $self->{__helper}->readFile($filename);
}

# See the comments in JavaXGettext.java for more information about the 
# following optional methods.
sub extractFromNonFiles {
    my ($self) = @_;
    
    return $self->SUPER::extractFromNonFiles()
        if !$self->can('extractFromNonFiles');
    
    return $self->{__helper}->extractFromNonFiles;
}

# We have to translate that from Java.
sub defaultKeywords {
    my ($self) = @_;

    return $self->SUPER::defaultKeywords()
        if !$self->{__helper}->can('defaultKeywords');
    
    return $self->{__helper}->defaultKeywords;

    # Turn the array of arrays returned by the Java class method into a Perl
    # Hash.  The array returned from Java is an Inline::Java::Array which
    # does not support splice().  We therefore have to copy it into a
    # plain array.
    my %keywords = map { 
        my @keyword = @{$_};
        $keyword[0] => [splice @keyword, 1] 
    } @{$self->{__helper}->defaultKeywords};

    return \%keywords;
}

sub languageSpecificOptions {
    my ($self) = @_;
    
    return $self->SUPER::extractFromNonFiles() 
        if !$self->{__helper}->can('languageSpecificOptions');

    return $self->{__helper}->languageSpecificOptions;
}

sub fileInformation {
    my ($self) = @_;
    
    return $self->SUPER::fileInformation() 
        if !$self->{__helper}->can('fileInformation');
    
    return $self->{__helper}->fileInformation;
}

sub canExtractAll {
    my ($self) = @_;
    
    return $self->SUPER::canExtractAll() 
        if !$self->{__helper}->can('canExtractAll');
    
    return $self->{__helper}->canExtractAll;
}

sub canKeywords {
    my ($self) = @_;
    
    return $self->SUPER::canKeywords() 
        if !$self->{__helper}->can('canKeywords');
    
    return $self->{__helper}->canKeywords;
}

sub canFlags {
    my ($self) = @_;
    
    return $self->SUPER::canFlags() 
        if !$self->{__helper}->can('canFlags');
    
    return $self->{__helper}->canFlags;
}

# This will not win a prize for clean software design.  You cannot invoke
# methods of Perl object from Java.  We therefore keep the most "current"
# instance of the extractor class in a variable $xgettext and call
# the methods on this instance.  This works without problems inside of a
# script which is sufficient for our needs.

package Locale::XGettext::Callbacks;

use strict;

use Scalar::Util qw(reftype);

sub __unbless($);

sub addEntry {
    my ($class, %entry) = @_;

    $xgettext->addEntry(\%entry);

    return 1;
}

sub option {
    my ($class, $name) = @_;

    return $xgettext->option($name);
}

sub keywords {
    my ($class) = @_;

    my $keywords = JavaXGettextKeywords->new;
    my $value = $xgettext->keywords;

    foreach my $key (keys %$value) {
        my $perldef = $value->{$key};
        my $javadef = JavaXGettextKeyword->new(
            $perldef->function,
            $perldef->singular, $perldef->plural,
            $perldef->context, $perldef->comment
        );
        
        $keywords->put($key, $javadef);
    }

    return $keywords;
}