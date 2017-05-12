package HTML::EmbeddedPerl;

use strict;
use warnings;

use Exporter;

our @ISA       = qw(Exporter);
our @EXPORT    = qw(ep header_out header content_type echo OPT_TAG_NON OPT_TAG_ALL OPT_TAG_EPL OPT_TAG_DOL OPT_TAG_PHP OPT_TAG_ASP);
our @EXPORT_OK = qw($EPLOPT $VERSION);

our $VERSION = '0.91';

use XSLoader;
XSLoader::load('HTML::EmbeddedPerl', $VERSION);

sub handler{
  my $r = shift;
  return 404 if(!-f $r->filename);
  my $c = _twepl_handler($r->filename);
  my %h = eval '%'.__PACKAGE__.'::HEADER;';
  my $t = eval '$'.__PACKAGE__.'::CONTYP;';
  foreach my $e(keys %h){
    $r->header_out($e, $h{$e});
  }
  $r->content_type($t);
  $r->puts($c);
  $r->rflush();
  0;
}

1;

__END__

=head1 NAME

HTML::EmbeddedPerl - The Perl embeddings for HTML.

=head1 SYNOPSYS

I<automatic> for mod_perl2.

=head1 DESCRIPTION

The Perl source code embeddings for HTML.

adding I<E<lt>([|:$?%])(p5|pl|pl5|perl|perl5)? Perl-Code $1E<gt>> to your HTML.

=head1 AUTHOR

TWINKLE COMPUTING <twinkle@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2010 TWINKLE COMPUTING All rights reserved.

=head1 LISENCE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
