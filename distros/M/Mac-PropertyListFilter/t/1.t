# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('Mac::PropertyList') };
BEGIN { use_ok('Mac::PropertyListFilter','xml_filter') };

#########################

{
  my $plist = Mac::PropertyList::parse_plist(<<_EOF_);
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>kAuto</key>
	<integer>1</integer>
	<key>kDimTime</key>
	<real>60.6</real>
</dict>
</plist>
_EOF_
  is_deeply($plist,{
    type => 'dict',
    value => {
      kAuto => {
        type => 'integer',
        value => 1,
      },
      kDimTime => {
        type => 'real',
        value => 60.6
      }
    }
  });
  is_deeply(xml_filter($plist),{
    kAuto => 1,
    kDimTime => 60.6
  });
}
{
  my $plist = Mac::PropertyList::parse_plist(<<_EOF_);
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CanvasColor</key>
	<dict>
		<key>a</key>
		<real>0.5</real>
		<key>w</key>
		<real>0.66666</real>
	</dict>
</dict>
</plist>
_EOF_
  is_deeply($plist,{
    type => 'dict',
    value => {
      CanvasColor => {
        type => 'dict',
        value => {
          a => {
            type => 'real',
            value => 0.5,
          },
          w => {
            type => 'real',
            value => 0.66666
          }
        }
      }
    }
  });
  is_deeply(
    xml_filter(
      $plist, [
        sub {
          my $input = shift;
          if(ref $input eq 'HASH' and
             defined $input->{a} and
             defined $input->{w}) {
            return [$input->{a},$input->{w}]
          }
        }
      ]
    ),
    { CanvasColor => [0.5,0.66666] }
  );
}
