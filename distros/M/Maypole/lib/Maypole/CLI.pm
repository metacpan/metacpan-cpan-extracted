package Maypole::CLI;
use UNIVERSAL::require;
use URI;
use URI::QueryParam;
use Maypole::Constants;

use strict;
use warnings;
my $package;
our $buffer;

# Command line action
CHECK {
    if ( ( caller(0) )[1] eq "-e" ) {
        $package->handler() == OK and print $buffer;
    }
}

sub import {
    $package = $_[1];
    $package->require;
    die "Couldn't require $package - $@" if $@;
    no strict 'refs';
    unshift @{ $package . "::ISA" }, "Maypole::CLI";
}

sub get_template_root { $ENV{MAYPOLE_TEMPLATES} || "." }

sub warn {
    my ($self,@args) = @_;
    my ($package, $line) = (caller)[0,2];
    warn "[$package line $line] ", @args ;
    return;
}

sub parse_location {
    my $self = shift;
    my $url  = URI->new( shift @ARGV );

    $self->preprocess_location();

    (my $uri_base = $self->config->uri_base) =~ s:/$::;
    my $root = URI->new( $uri_base )->path;
    $self->{path} = $url->path;
    $self->{path} =~ s:^$root/?::i if $root;
    $self->parse_path;
    $self->parse_args($url);
}

sub parse_args {
    my ( $self, $url ) = @_;
    $self->{params} = $url->query_form_hash;
    $self->{query}  = $url->query_form_hash;
}

sub send_output { $buffer = shift->{output} }

sub call_url {
    my $self = shift;
    local @ARGV = @_;
    $package->handler() == OK and return $buffer;
}


1;

=head1 NAME

Maypole::CLI - Command line interface to Maypole for testing and debugging

=head1 SYNOPSIS

  % setenv MAYPOLE_TEMPLATES /var/www/beerdb/
  % perl -MMaypole::CLI=BeerDB -e1 http://localhost/beerdb/brewery/frontpage

=head1 DESCRIPTION

This module is used to test Maypole sites without going through a web
server or modifying them to use a CGI frontend. To use it, you should
first either be in the template root for your Maypole site or set the
environment variable C<MAYPOLE_TEMPLATES> to the right value.

Next, you import the C<Maypole::CLI> module specifying your base Maypole
subclass. The usual way to do this is with the C<-M> flag: 
C<perl -MMaypole::CLI=MyApp>. This is equivalent to:

    use Maypole::CLI qw(MyApp);

Now Maypole will automatically call your application's handler with the
URL specified as the first command line parameter. This should be the
full URL, starting from whatever you have defined as the C<uri_base> in
your application's configuration, and may include query parameters.

The Maypole HTML output should then end up on standard output.

=head1 Support for testing

The module can also be used as part of a test script. 

When used programmatically, rather than from the command line, its
behaviour is slightly different. 

Although the URL is taken from C<@ARGV> as normal, your application's
C<handler> method is not called automatically, as it is when used on the
command line; you need to call it manually. Additionally, when
C<handler> is called, the output is not printed to standard output but
stored in C<$Maypole::CLI::buffer>, to allow you to check the contents
more easily.

For instance, a test script could look like this:

    use Test::More tests => 3;
    use Maypole::CLI qw(BeerDB);
    use Maypole::Constants;
    $ENV{MAYPOLE_TEMPLATES} = "t/templates";

    # Hack because isa_ok only supports object isa not class isa
    isa_ok( (bless {},"BeerDB") , "Maypole");

    like(BeerDB->call_url("http://localhost/beerdb/"), qr/frontpage/, "Got the front page");

    like(BeerDB->call_url("http://localhost/beerdb/beer/list"), qr/Organic Best/, "Found a beer in the list");

=head1 METHODS 

=over 

=item call_url

for use in scripts. takes an url as argument, and returns the buffer. 

=back


=head1 Implementation

This class overrides a set of methods in the base Maypole class to provide it's 
functionality. See L<Maypole> for these:

=over

=item get_template_root

=item parse_args

=item parse_location

=item send_output

=item warn

=back

=cut 
