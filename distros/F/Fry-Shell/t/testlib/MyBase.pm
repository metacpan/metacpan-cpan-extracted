#overrides Fry::Base
package MyBase;

our %coreHash = (qw/lib Fry::Lib cmd Fry::Cmd var Fry::Var opt Fry::Opt sub Fry::Sub obj Fry::Obj type
Fry::Type/);
sub sh {return 'FakeSh'}
sub var { $coreHash{var}}
sub sub { $coreHash{sub}}
sub opt { $coreHash{opt}}
sub obj { $coreHash{obj}}
sub type { $coreHash{type}}
sub lib { $coreHash{lib}}
sub cmd { $coreHash{cmd}}
sub Caller { return 'CmdClass' }
sub Sub { return shift->sub->call(@_) }
sub setVar ($%) { shift->var->setVar(@_) }
sub Var ($) { return  shift->var->Var(shift()) }
#sub Var { return shift->var->get($_[0],'value') }
#sub setVar { shift->setMany(@_) }
our %flag;
sub Flag { return $flag{$_[1]} }
sub setFlag {$flag{$_[1]} = $_[2]; }
1;
