use File::Find qw();
use ExtUtils::Manifest qw();
no warnings 'redefine';
*{ExtUtils::Manifest::find} = sub {
  File::Find::find({ %{$_[0]}, follow=>0, follow_fast=>0, follow_skip=>2 }, @_[1..$#_]);
};
