package Labyrinth::Writer::Render::PSGI;

use warnings;
use strict;

our $VERSION = '1.02';

=head1 NAME

Labyrinth::Writer::Render::PSGI - Output Handler via PSGI for Labyrinth.

=head1 SYNOPSIS

  use Labyrinth::Writer::Render::PSGI;
  my $render = Labyrinth::Writer::Render::PSGI->new();

  $render->redirect($url);          # HTTP redirect

  $render->publish($format, $text);

=head1 DESCRIPTION

Use CGI::PSGI to output text or redirect.

=cut

# -------------------------------------
# Library Modules

use CGI::PSGI;
use IO::File;

use Labyrinth::Variables;

# -------------------------------------
# Variables

my $cgi = CGI::PSGI->new($settings{psgi}{env});

# -------------------------------------
# The Subs

=head1 METHODS

=over 4

=item new

Object constructor.

=item redirect($url)

Redirect to given URL.

=item binary($vars)

Shorthand output of binary data and files.

=item publish($format, $text)

Publishes text output.

=back

=cut

sub new {
    my($class) = @_;

    my $self = bless { cgi => 1 }, $class;
    $self;
}

sub redirect {
    my ($self, $url) = @_;
    ($settings{psgi}{status},$settings{psgi}{headers}) = $cgi->psgi_redirect($url);
}

sub binary {
    my ($self, $vars) = @_;

    my $fh = IO::File->new($settings{webdir}.'/'.$vars->{file},'r');
    if($fh) {
        ($settings{psgi}{status},$settings{psgi}{headers}) = $cgi->psgi_header( -type => $vars->{ctype} );
        my $buffer;
        while(read($fh,$buffer,1024)) { $settings{psgi}{body} .= $buffer }
        $fh->close;
    }
}

sub publish {
    my ($self, $headers, $body) = @_;

    my %cgihash = map { '-' . $_ => $headers->{$_} } grep {$headers->{$_}} qw(type status cookie attachment);

    ($settings{psgi}{status},$settings{psgi}{headers}) = $cgi->psgi_header( %cgihash );
    $settings{psgi}{body} .= $$body;
}

1;

__END__

=head1 SEE ALSO

L<CGI::PSGI>,
L<Labyrinth>

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2013-2014 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
