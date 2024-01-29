use Test::More;

use_ok('HTML::Selector::Element', qw(find));
require_ok('HTML::TreeBuilder');

package HTML::TreeBuilder::Html5 {
    @ISA = qw(HTML::TreeBuilder);
    # All elements new in html5 require a closing tag except these two:
    $HTML::Tagset::emptyElement{$_} = 1 foreach qw(keygen menuitem);
    # keygen is a form element. All form elements are in possible_strict_p_content.
    $HTML::Tagset::isFormElement{$_} = $HTML::Tagset::is_Possible_Strict_P_Content{$_} = 1 foreach qw(keygen);

    sub new {
        # change/add default options
        return shift->SUPER::new(ignore_unknown => 0, store_comments => 1, @_, xml => []);
    }

    sub start {
        my ( $self, $tag, $attr ) = @_;
        push @{$self->{_xml}}, $tag if $tag eq 'svg' or $tag eq 'math';
        if(@{$self->{_xml}} ) {
            my $e = $self->element_class->new( $tag, %$attr );
            $self->insert_element($e);
            return $e;
        }
        elsif($HTML::TreeBuilder::isKnown{$tag}) {
            shift->SUPER::start(@_);
        }
        else {
            local $HTML::TreeBuilder::isBodyElement{$tag} = 1;
            shift->SUPER::start(@_);
        }
    }

    sub end {
        my ( $self, $tag, @stop ) = @_;
        if(!ref $tag && @{$self->{_xml}} && $self->{_xml}[-1] eq $tag) {
            pop @{$self->{_xml}};
        }
        shift->SUPER::end(@_);
    }
}

ok(my $dom = HTML::TreeBuilder::Html5->new_from_content(<<'__HTML_1__'), 'parse using HTML::TreeBuilder::Html5');
<div class="row pb-3 mt-3">
  <div class="col-12 my-2"><a class="menu_icon" href="a"><div class="col-12 pl-1">
        <div class="row align-items-center">
          <div class="col-auto tx-menu-btn"><svg class="tx-btn-icon" viewbox="0 0 121.76 121.76" xmlns="http://www.w3.org/2000/svg"><defs><style>.a0b3875b-5eab-4e60-99d9-7a94f151dc4a{fill:none;stroke:#6ec8ff;stroke-miterlimit:10;stroke-width:1.75px;}.b57654db-329a-4144-bf34-8b016104d36f{fill:#6ec8ff;}</style></defs><g data-name="Layer 2" id="a662c8ad-319d-47ab-8cce-f14858af57b7"><g data-name="Login" id="ebf38776-540c-4d73-824e-f3061fde9e60"><circle class="a0b3875b-5eab-4e60-99d9-7a94f151dc4a" cx="60.88" cy="60.88" r="60"></circle><path class="b57654db-329a-4144-bf34-8b016104d36f" d="M69.51,58.93a15.5,15.5,0,1,0-4,1.65,22.2,22.2,0,0,1-4.07,1.2l-.53.1a23.73,23.73,0,0,1-3.79.32A22.64,22.64,0,0,1,50,61a29.19,29.19,0,0,0-16.5,26.28h58.4A29.2,29.2,0,0,0,69.51,58.93Z"></path></g></g></svg></div>
          <div class="col pl-2"><span class="text">Profiles</span></div>
        </div>
      </div></a></div>
  <div class="col-12 my-2"><a class="menu_icon" href="b"><div class="col-12 pl-1">
        <div class="row align-items-center">
          <div class="col-auto tx-menu-btn"><svg class="tx-btn-icon" viewbox="0 0 121.76 121.76" xmlns="http://www.w3.org/2000/svg"><defs><style>.ada108f7-65e5-47c9-b7c2-623f009bf8db{fill:none;stroke:#6ec8ff;stroke-miterlimit:10;stroke-width:1.75px;}.f9984f5c-666a-4f77-b6b0-cf5e2fae5a68{fill:#6ec8ff;}</style></defs><g data-name="Layer 2" id="aed18c6f-bbcc-4314-bc9c-7fc564c015fe"><g data-name="Bedrijf" id="b8adbe23-f062-4afa-b57f-3e88eeea3bd9"><circle class="ada108f7-65e5-47c9-b7c2-623f009bf8db" cx="60.88" cy="60.88" r="60"></circle><path class="f9984f5c-666a-4f77-b6b0-cf5e2fae5a68" d="M88.05,39.39a5.52,5.52,0,0,0-5.63,0l-14,8.19V44.26a5.63,5.63,0,0,0-5.63-5.62,5.55,5.55,0,0,0-2.83.77L43.87,48.79l5.2-6.06V32.11a5.63,5.63,0,0,0-5.63-5.62H36.5a5.62,5.62,0,0,0-5.62,5.62V80.86a5.63,5.63,0,0,0,5.62,5.63H85.25a5.64,5.64,0,0,0,5.63-5.63V44.26A5.56,5.56,0,0,0,88.05,39.39Zm-44,33.53a5.19,5.19,0,1,1,5.18-5.18A5.18,5.18,0,0,1,44.09,72.92Zm16.87,0a5.19,5.19,0,1,1,5.19-5.18A5.18,5.18,0,0,1,61,72.92Zm16.88,0A5.19,5.19,0,1,1,83,67.74,5.18,5.18,0,0,1,77.84,72.92Z"></path></g></g></svg></div>
          <div class="col pl-2"><span class="text">Organisations</span></div>
        </div>
      </div></a></div>
  <div class="col-12 my-2"><a class="menu_icon" href="c"><div class="col-12 pl-1">
        <div class="row align-items-center">
          <div class="col-auto tx-menu-btn"><img class="align-self-center img-circle avatar avatar-circle img-fluid rounded-circle" src="./821_files/picture" /></div>
          <div class="col pl-2"><span class="text">My profile</span></div>
        </div>
      </div></a></div>
  <div class="col-12 my-2"><a class="menu_icon" href="d"><div class="col-12 pl-1">
        <div class="row align-items-center">
          <div class="col-auto tx-menu-btn"><svg class="tx-btn-icon" data-name="Alerts" id="a347d555-458e-44d4-9a31-6050dd845e41" viewbox="0 0 121.76 121.76" xmlns="http://www.w3.org/2000/svg"><defs><style>.afc58951-248b-44e7-9c92-d69051e57266{fill:#23b26f;}.b8ba1a1e-bf04-4f47-a4bd-6109d8cc30c4{fill:none;stroke:#23b26f;stroke-miterlimit:10;stroke-width:1.75px;}</style></defs><path class="afc58951-248b-44e7-9c92-d69051e57266" d="M75.79,101.85a7.3,7.3,0,0,0,7.3-7.3H68.49A7.37,7.37,0,0,0,75.79,101.85Z" transform="translate(-14.12 -14.77)"></path><polygon class="afc58951-248b-44e7-9c92-d69051e57266" points="68.97 77.22 68.97 79.77 54.37 79.77 68.97 77.22"></polygon><path class="afc58951-248b-44e7-9c92-d69051e57266" d="M92.29,64.8A16.17,16.17,0,0,0,88,52.9a15.73,15.73,0,0,0-9.6-4.5v-.9a2.9,2.9,0,0,0-5.8,0v1c-7.7,1.3-13,7.6-13.2,16.2V77.6l-6.9,15H99l-6.7-15Z" transform="translate(-14.12 -14.77)"></path><circle class="b8ba1a1e-bf04-4f47-a4bd-6109d8cc30c4" cx="60.88" cy="60.88" r="60"></circle></svg></div>
          <div class="col pl-2"><span class="text">Notifications</span></div>
        </div>
      </div></a></div>
  <div class="col-12 my-2"><a class="menu_icon" href="e"><div class="col-12 pl-1">
        <div class="row align-items-center">
          <div class="col-auto tx-menu-btn fa"><i class="fas fa-comments"></i></div>
          <div class="col pl-2"><span class="text">Messages</span></div>
        </div>
      </div></a></div>
  <div class="col-12 my-2"><a class="menu_icon" href="f"><div class="col-12 pl-1">
        <div class="row align-items-center">
          <div class="col-auto tx-menu-btn fa"><i class="fas fa-star"></i></div>
          <div class="col pl-2"><span class="text">Ratings</span></div>
        </div>
      </div></a></div>
  <div class="col-12 my-2"><a class="menu_icon" href="g"><div class="col-12 pl-1">
        <div class="row align-items-center">
          <div class="col-auto tx-menu-btn"><svg class="tx-btn-icon" data-name="Meer ..." id="f0adcc2d-0ac1-470c-b394-79e3e39fb2bb" viewbox="0 0 121.76 121.76" xmlns="http://www.w3.org/2000/svg"><defs><style>.a29b1697-0065-4fd5-811b-fbba40f279c5{fill:#23b26f;}.fc7693bb-f119-4a18-95dd-3e99513a5082{fill:none;stroke:#23b26f;stroke-miterlimit:10;stroke-width:1.75px;}</style></defs><circle class="a29b1697-0065-4fd5-811b-fbba40f279c5" cx="60.88" cy="60.88" r="5.17"></circle><circle class="a29b1697-0065-4fd5-811b-fbba40f279c5" cx="81.35" cy="60.88" r="5.17"></circle><circle class="a29b1697-0065-4fd5-811b-fbba40f279c5" cx="40.41" cy="60.88" r="5.17"></circle><circle class="fc7693bb-f119-4a18-95dd-3e99513a5082" cx="60.88" cy="60.88" r="60"></circle></svg></div>
          <div class="col pl-2"><span class="text">Settings</span></div>
        </div>
      </div></a></div>
  <div class="col-12 my-2"><a class="menu_icon" href=""><div class="col-12 pl-1">
        <div class="row align-items-center">
          <div class="col-auto tx-menu-btn fa"><i class="fal fa-sign-out"></i></div>
          <div class="col pl-2"><span class="text">Sign Out</span></div>
        </div>
      </div></a></div>
</div>
__HTML_1__

my @a = $dom->find('a');
is(scalar @a, 8, 'find all `a`');
is(scalar $dom->find('a'), $a[0], 'find first `a`');
my @r = $dom->find_by_tag_name('div')->find('> div > a');
is_deeply(\@r, \@a, 'find all `> div > a`');
my $r = $dom->find_by_tag_name('div')->find('> div > a');
is($r, $a[0], 'find first `> div > a`');
my @div = map $_->parent, @a;
@r = $dom->find_by_tag_name('div')->find('> div');
is_deeply(\@r, \@div, 'find all `> div`');
$r = $dom->find_by_tag_name('div')->find('> div');
is($r, $div[0], 'find first `> div`');
shift @div;
@r = $dom->find_by_tag_name('div')->find('> div + div');
is_deeply(\@r, \@div, 'find all `> div + div`');
$r = $dom->find_by_tag_name('div')->find('> div + div');
is($r, $div[0], 'find first `> div + div`');

splice @div, 0, 2;
$div = shift @div;
@r = $div->find('~ div');
is_deeply(\@r, \@div, 'find all `~ div`');
$r = $div->find('~ div');
is($r, $div[-4.], 'find first `~ div`');
@r = $div->find('~ div a');
is_deeply(\@r, [ @a[-4..-1] ], 'find all `~ div a`');
$r = $div->find('~ div a');
is($r, $a[-4.], 'find first `~ div a`');


done_testing();


