package Devel::WxProf::Grid;
use strict; use warnings;
use Wx;
use base qw(Wx::Grid Class::Accessor::Fast);
use version; our $VERSION = qv(0.0.1);

__PACKAGE__->mk_accessors(qw(data));
1;