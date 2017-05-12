#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;
use FindBin qw($Bin);
use LaTeX::Pod;
use Test::More tests => 2;

my %insert = (
    umlauts => 'ä Ä ü Ü ö Ö',
    newline => "\n",
);

my $parser = LaTeX::Pod->new(File::Spec->catfile($Bin, 'data', 'basic.t.in'));
$parser->convert;

my $data     = do { local $/; <DATA> };
my @expected = split /\n\n/, $data;
my $subst    = sub { my $pod = shift; $pod =~ s/(\$\S+)/$1/eeg; $pod };

is_deeply($parser->_pod_get, [ map $subst->($_), @expected ]);
is_deeply([ split /\n+/, $parser->convert ], [ split /\n+/, $subst->($data) ]);

__DATA__
=for comment this is a report

=head1 title

Fusce lobortis luctus risus, in consequat arcu porttitor quis.
Curabitur interdum ligula et dolor commodo pulvinar.

Etiam vitae dolor augue

=head1 chapter1 $insert{umlauts}

=head2 section1 $insert{umlauts}

Lorem ipsum dolor sit amet, ...

=over 4

=item 1. consectetur adipiscing elit.

=item 2. Morbi lobortis purus non enim

=back

=over 5

=item 1. Aliquam

=back

=over 6

=item 1. turpis

=back

=over 4

=item 3. leo

=item 5. Quisque lobortis

=item 6. Duis sed lacus lectus,

=back

Cras pharetra dui quis

=for comment this is the end of an enumerated list

fringilla auctor interdum tortor aliquet.

=head3 subsection1 $insert{umlauts}

Nunc B<feugiat> condimentum$insert{newline}

=head3 subsection2

=for comment this is a subsection

=over 4

=item * C<urna> nec consectetur.

=back

=over 5

=back

Aliquam arcu augue,$insert{newline}
Aliquam arcu augue,$insert{newline}

=head4 subsubsection1

=over 4

=item B<dapibus> # $ % & _ { } sed

=back

=head4 subsubsection2

=over 4

=item * vestibulum sed, $insert{umlauts}

=back

=over 4

=item - item 1

=back

Nam id

=head1 chapter2

=head2 section2

sodales
sodales

  eget
   enim.

Duis arcu sapien

=head3 subsection1

C<Proin>
C<Proin>

=head2 section3

quis I<elit>

=over 4

=item * Quisque vulputate

Curabitur in neque
Donec molestie
# $ % & _ { }

=item * Etiam ac mauris

=back

=over 5

=item * sem sit amet

=item * ligula rutrum vel

=back

=over 4

=item * eu bibendum leo

=back

                .'.
  '..cll.    .lxxdxl'
  ',:clkx. .;OK0ko;ll;
   okoddc.oOo,;l::'.;c;
   xoldo'dkl'..':;;:,:;:
   lKo,c'lkO,.,,:;,. ;;lo.
    :xl,;dxKlc;'odddxKd:;c
      .,.kKOoxoc;x0d.xx,;:
         d0o 00d l0. ,O;.
         ox ;lc. ;c   o:
         :: .,' ..    c'
         ;    .c,.    ,
        ..   .'.',   .l.
       ;'.           .,

=over 4

=back

=cut
