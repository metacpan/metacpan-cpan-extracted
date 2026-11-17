package Example::Flow::Probe;
use Example::Sugar::RoleDSL;
step 'Probe input' => probe => sub { return {ok=>1} };
no Example::Sugar::RoleDSL;
1;
