# Test localization class and its subclasses
# Copyright (c) 2003 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

package T_L10N;
use base qw(Locale::Maketext::Gettext);

return 1;

package T_L10N::en;
use base qw(Locale::Maketext::Gettext);

return 1;

package T_L10N::zh_tw;
use base qw(Locale::Maketext::Gettext);

return 1;

package T_L10N::zh_cn;
use base qw(Locale::Maketext::Gettext);

return 1;
