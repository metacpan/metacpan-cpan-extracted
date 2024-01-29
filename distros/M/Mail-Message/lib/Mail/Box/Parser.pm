# Copyrights 2001-2023 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::Parser;
use vars '$VERSION';
$VERSION = '3.015';

use base 'Mail::Reporter';

use strict;
use warnings;

use Carp;


sub new(@)
{   my $class = shift;

    $class eq __PACKAGE__
    ? $class->defaultParserType->new(@_)   # bootstrap right parser
    : $class->SUPER::new(@_);
}

sub init(@)
{   my ($self, $args) = @_;

#warn "PARSER type=".ref $self,$self->VERSION;
    $self->SUPER::init($args);

    $self->{MBP_mode} = $args->{mode} || 'r';

    unless($self->{MBP_filename} = $args->{filename} || ref $args->{file})
    {    $self->log(ERROR => "Filename or handle required to create a parser.");
         return;
    }

    $self->start(file => $args->{file});
}

#------------------------------------------


sub start(@)
{   my $self = shift;
    my %args = (@_, filename => $self->filename, mode => $self->{MBP_mode});

    $self->openFile(\%args)
        or return;

    $self->takeFileInfo;

    $self->log(PROGRESS => "Opened folder $args{filename} to be parsed");
    $self;
}

#------------------------------------------


sub stop()
{   my $self     = shift;

    my $filename = $self->filename;

#   $self->log(WARNING => "File $filename changed during access.")
#      if $self->fileChanged;

    $self->log(NOTICE  => "Close parser for file $filename");
    $self->closeFile;
}


sub restart()
{   my $self     = shift;
    my $filename = $self->filename;

    $self->closeFile;
    $self->openFile( {filename => $filename, mode => $self->{MBP_mode}} )
        or return;

    $self->takeFileInfo;
    $self->log(NOTICE  => "Restarted parser for file $filename");
    $self;
}


sub fileChanged()
{   my $self = shift;
    my ($size, $mtime) = (stat $self->filename)[7,9];
    return 0 if !defined $size || !defined $mtime;
    $size != $self->{MBP_size} || $mtime != $self->{MBP_mtime};
}
    

sub filename() {shift->{MBP_filename}}

#------------------------------------------


sub filePosition(;$) {shift->NotImplemented}


sub pushSeparator($) {shift->notImplemented}


sub popSeparator($) {shift->notImplemented}


sub readSeparator($) {shift->notImplemented}


sub readHeader()    {shift->notImplemented}


sub bodyAsString() {shift->notImplemented}


sub bodyAsList() {shift->notImplemented}


sub bodyAsFile() {shift->notImplemented}


sub bodyDelayed() {shift->notImplemented}


sub lineSeparator() {shift->{MBP_linesep}}

#------------------------------------------


sub openFile(@) {shift->notImplemented}


sub closeFile(@) {shift->notImplemented}


sub takeFileInfo()
{   my $self     = shift;
    @$self{ qw/MBP_size MBP_mtime/ } = (stat $self->filename)[7,9];
}


my $parser_type;

sub defaultParserType(;$)
{   my $class = shift;

    # Select the parser manually?
    if(@_)
    {   $parser_type = shift;
        return $parser_type if $parser_type->isa( __PACKAGE__ );

        confess "Parser $parser_type does not extend "
              . __PACKAGE__ . "\n";
    }

    # Already determined which parser we want?
    return $parser_type if $parser_type;

    # Try to use C-based parser.
    eval 'require Mail::Box::Parser::C';
#warn "C-PARSER errors $@\n" if $@;

    return $parser_type = 'Mail::Box::Parser::C'
        unless $@;

    # Fall-back on Perl-based parser.
    require Mail::Box::Parser::Perl;
    $parser_type = 'Mail::Box::Parser::Perl';
}

#------------------------------------------


sub DESTROY
{   my $self = shift;
    $self->stop;
    $self->SUPER::DESTROY;
}

1;
