package Labyrinth::Writer::Render::CGI;

use warnings;
use strict;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
$VERSION = '5.32';

=head1 NAME

Labyrinth::Writer::Render::CGI - Output Handler via CGI for Labyrinth.

=head1 SYNOPSIS

  use Labyrinth::Writer::Render::CGI;
  my $render = Labyrinth::Writer::Render::CGI->new();

  $render->redirect($url);          # HTTP redirect

  $render->publish($format, $text);

=head1 DESCRIPTION

Use CGI to output text or redirect.

=cut

# -------------------------------------
# Library Modules

use CGI;
use IO::File;

use Labyrinth::Audit;
use Labyrinth::Globals;
use Labyrinth::Variables;

# -------------------------------------
# Variables

my $cgi = CGI->new();

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
    print $cgi->redirect($url);
}

sub binary {
    my ($self, $vars) = @_;

    my $fh = IO::File->new($settings{webdir}.'/'.$vars->{file},'r');
    if($fh) {
        print $cgi->header( -type => $vars->{ctype} );
        my $buffer;
        while(read($fh,$buffer,1024)) { print $buffer }
        $fh->close;
    }
}

sub publish {
    my ($self, $headers, $body) = @_;

    my %cgihash = map { '-' . $_ => $headers->{$_} } grep {$headers->{$_}} qw(type status cookie attachment charset);
    #LogDebug("CGI Hash=".Dumper(\%cgihash));

    print $cgi->header( %cgihash ) . $$body;
}

1;

__END__

=head1 SEE ALSO

  CGI,
  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
