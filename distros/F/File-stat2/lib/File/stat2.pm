package File::stat2;

=head1 NAME

File::stat2 -- similar to File::stat, but with access/create/modification times down to nanosecond

=head1 SYNOPSIS

Same interface as File::stat :

  use File::stat;
  use File::stat2;
   
  my $st1 = stat  ($file);
  my $st2 = stat2 ($file);

but times are double precision numbers instead of bare integers : 

  print $st1->mtime (); # 1733990636
  print $st2->mtime (); # 1733990636.8844

=head1 DESCRIPTION

File::stat is great, but it is not possible to access time stamps
with the highest possible precision. File::stat2 solves this issue.

=head1 SEE ALSO

File::stat, stat (2)

=head1 AUTHOR

pmarguinaud@hotmail.com

=cut

use 5.016003;
use strict;
use warnings;

use base qw (File::stat);

our @EXPORT = qw (stat2);
our $VERSION = '0.03';

require XSLoader;
XSLoader::load('File::stat2', $VERSION);

sub stat2
{
  if (my @st = &_stat2 ($_[0]))
    {
      return bless \@st, __PACKAGE__;
    }
}

1;
