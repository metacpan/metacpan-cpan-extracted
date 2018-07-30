package ew;

use strictures 2;
use Module::Runtime;

our $VERSION = '1.002002'; # VERSION

sub _mew {
  print <<'EOMEW';
                 ________________
                |                |_____    __
                |  I Love You!   |     |__|  |_________
                |________________|     |::|  |        /
   /\**/\       |                \.____|::|__|      <
  ( o_o  )_     |                      \::/  \._______\
   (u--u   \_)  |
    (||___   )==\
  ,dP"/b/=( /P"/b\
  |8 || 8\=== || 8
  `b,  ,P  `b,  ,P
    """`     """`

EOMEW
  exit 0;
}

BEGIN {
    my $package;
    sub import {
        _mew() if $0 eq '-';
        $package = $_[1] || 'Class';
        $package =~ s/^\+// and require_module $package;
    }
    use Filter::Simple sub { s/^/package $package;\nuse Mew;\n/; }
}

1;
__END__

=encoding utf8

=for stopwords oneliners

=head1 NAME

ew - syntactic sugar for Mew oneliners

=head1 SYNOPSIS

  perl -Mew=Foo -e 'has bar => Str, default => "baz"; print Foo->new->bar'

  # loads an existing class and re-"opens" the package definition
  perl -Mew=+My::Class -e 'print __PACKAGE__->new->bar'

=head1 DESCRIPTION

ew.pm is a simple source filter that adds C<package $name; use Mew;> to the
beginning of your script, intended for use on the command line via the -M
option.

=head1 SUPPORT

See L<Mew> for support and contact information.

=head1 AUTHORS

See L<Mew> for authors.

=head1 COPYRIGHT AND LICENSE

See L<Mew> for the copyright and license.

=cut
