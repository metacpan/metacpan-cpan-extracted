use Test::Base;
use FormValidator::LazyWay;
use FindBin;
use File::Spec;
use CGI;
use YAML::Syck;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );
use Data::Dumper;
use utf8;

no warnings 'once';
local $YAML::Syck::ImplicitUnicode = 1;
use warnings;

plan tests => 1 * blocks;

run {
    my $block = shift;

    my $cgi = new CGI( $block->param ) ;

    my $config = Load($block->yaml);
    my $fv = FormValidator::LazyWay->new( config => $config );

    my $res = $fv->check( $cgi, { required => [qw/username/], stash => $block->stash } );

    ok( $res->valid->{username} );
}

__END__
=== sccess1
--- yaml
rules :
  - String
setting :
  strict :
    username :
      rule :
        - String#stash_test :
            min : 4
            max : 12
lang : ja
labels :
    ja :
        username : ユーザーネーム
--- param eval
{ username => 'vkgtaro' }
--- stash eval
{ username => 'test' }
=== sccess2
--- yaml
rules :
  - String
setting :
  strict :
    username :
      rule :
        - String#stash_test :
            min : 4
            max : 12
lang : ja
labels :
    ja :
        username : ユーザーネーム
--- param eval
{ username => 'vkgtaro' }
--- stash eval
{ username => { this => 'hash' } }
