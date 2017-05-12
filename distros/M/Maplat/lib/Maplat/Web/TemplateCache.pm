# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::TemplateCache;
use strict;
use warnings;

use base qw(Maplat::Web::BaseModule);
use Template;
use HTML::Entities;

our $VERSION = 0.995;

use Maplat::Helpers::FileSlurp qw(slurpBinFile);
use Carp;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class
    
    $self->{processor} = Template->new({
        PLUGINS => {
            tr => 'Maplat::Web::TT::Translate',
        },  
    });
    if(!defined($self->{processor})) {
        croak("Failed to load template engine");
    }
    
    return $self;
}

sub reload {
    my ($self) = shift;
    delete $self->{cache} if defined $self->{cache};

    my %files;

    my @DIRS = reverse @INC;
    if(defined($self->{EXTRAINC})) {
        push @DIRS, @{$self->{EXTRAINC}};
    }

    foreach my $view (@{$self->{view}}) {
        foreach my $bdir (@DIRS) {
            next if($bdir eq "."); # Load "./" at the end
            my $fulldir = $bdir . "/" . $view->{path};
            print "   ** checking $fulldir \n";
            if(-d $fulldir) {
                #print "   **** loading extra template files\n";
                $self->load_dir($fulldir, $view->{base}, \%files);
            }
        }
        { # Load "./"
            my $fulldir = $view->{path};
            print "   ** checking $fulldir \n";
            if(-d $fulldir) {
                #print "   **** loading local template files\n";
                $self->load_dir($fulldir, $view->{base}, \%files);
            }
        }
    }

    $self->{cache} = \%files;  
    return;
}

sub load_dir {
    my ($self, $dir, $base, $files) = @_;
    
    $base =~ s/^\///o;
    $base =~ s/\/$//o;
    
    opendir(my $dfh, $dir) or croak($!);
    while((my $fname = readdir($dfh))) {
        next if($fname !~ /\.tt$/);
        my $nfname = $dir . "/" . $fname;
        my $kname = $base . '/' . $fname;
        $kname =~ s/^\///o;
        $kname =~s /\.tt$//g;
        my $data = slurpBinFile($nfname);
        $files->{$kname} = $data;
    }
    closedir($dfh);
    return;
}

sub register {
    my $self = shift;
    # Templates don't register themself
    return;
}

sub get {
    my ($self, $name, $uselayout, %webdata) = @_;
    return unless defined($self->{cache}->{$name});
    
    #return undef unless defined($self->{cache}->{$layout});
    
    # Run a prerender callback on our webdata, so modules
    # like the "views" module can add missing data depending
    # on what the current module put into webdata
    $self->{server}->prerender(\%webdata);
    
    my $fullpage;
    
    my $layoutname = $self->{layout};
    if(defined($webdata{UserLayout}) && defined($self->{cache}->{$webdata{UserLayout}})) {
        $layoutname = $webdata{UserLayout};
    }
    
    if($uselayout) {
        $fullpage = $self->{cache}->{$layoutname};
        my $page = $self->{cache}->{$name};
        $fullpage =~ s/XX_BODY_XX/$page/;
    } else {
        $fullpage = $self->{cache}->{$name};
    }
    
    my $output;
    $self->{processor}->process(\$fullpage, \%webdata, \$output);
    if(defined($self->{processor}->{_ERROR}) &&
            $self->{processor}->{_ERROR}) {
        $self->{LastError} = $self->{processor}->{_ERROR};
        print STDERR $self->{processor}->{_ERROR}->[1] . "\n";
    }
    return $output;
}

sub quote {
    my ($self, $val) = @_;
    
    return encode_entities($val);
}

sub hashquote {
    my ($self, $hash, @keys) = @_;
    
    foreach my $key(@keys) {
        if(defined($hash->{$key})) {
            $hash->{$key} = $self->quote($hash->{$key});
        } else {
            $hash->{$key} = "";
        }
    }
    return 1;
}

sub arrayquote {
    my ($self, $array);
    
    my $cnt = scalar @$array;

    for(my $i; $i < $cnt; $i++) {
        if(!defined($array->[$i])) {
            $array->[$i] = "";
        } else {
            $array->[$i] = $self->quote($array->[$i]);
        }
    }
    return 1;
}

sub unquote {
    my ($self, $val) = @_;
    
    return decode_entities($val);    
}

1;
__END__

=head1 NAME

Maplat::Web::TemplateCache - provide template caching and rendering

=head1 SYNOPSIS

This module provides template rendering as well as caching the template files

=head1 DESCRIPTION

During the reload() calls, this modules loads all template files in the configured directory
into RAM and renders them quite fast.

The template rendering can optionally use "meta" rendering with a base template. This is for example
used to render the complete layout of a page, and modules only have templates that use only the changing
part of the page - this way, you only have to have one global layout and only write the changing part
of the page for every module.

=head1 Configuration

        <module>
                <modname>templates</modname>
                <pm>TemplateCache</pm>
                <options>
            <view>
                <path>MaplatWeb/Templates</path>
                <base>/</base>
            </view>
            <view>
                <path>some/other/relative/path</path>
                <base>myothertemplates/</base>
            </view>
                        <!-- Layout-Template to use for complete pages -->
                        <layout>maplatlayout</layout>
                </options>
        </module>

layout is the template name used in meta-rendering.

=head2 get

The one public function to call in this module is get(), in the form of:

  $templatehandle->get($name, $uselayout, %webdata);

$name if the name of the template file (without the .tt suffix)

$uselayout is a boolean, indicating if meta-rendering with the configured layout.

%webdata is a hash that is passed through to the template toolkit.

=head2 quote

HTML-encodes (quotes) a scalar. Takes one argument (the value to quote) and returns the quoted value.

=head2 unquote

The reverse of quote(), takes an encoded value and returns the decoded (unquoted) one.

=head2 arrayquote

Similar to quote(), but HTML-encodes all values of an array. This works in-place, actually changing
your array instead of working on a copy! Due to this, it should work on even huge arrays, with the downside
of changing the callers data directly.

Takes one argument, a reference to the array to quote.

Warning: This function is designed to work only on simple arrays, elements that are references to sub-structures (
scalars, hashes, arrays, functions,...) will lead to undefined behavior!

=head2 hashquote

Similar to quote(), but HTML-encodes all values of a hash. This works in-place, actually changing
your hash instead of working on a copy! Due to this, it should work on even huge hashes, with the downside
of changing the callers data directly.

Takes one argument, a reference to the hash to quote.

Warning: This function is designed to work only on simple hashes, elements that are references to sub-structures (
scalars, hashes, arrays, functions,...) will lead to undefined behavior!

=head2 load_dir

Internal function.

=head1 Dependencies

This module is a basic web module and does not depend on other web modules.

=head1 SEE ALSO

Maplat::Web

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
