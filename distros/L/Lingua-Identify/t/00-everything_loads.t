use Test::More tests => 16;
BEGIN { use_ok('Lingua::Identify', ':all') };

can_ok(__PACKAGE__,'langof');
can_ok(__PACKAGE__,'langof_file');
can_ok(__PACKAGE__,'confidence');
can_ok(__PACKAGE__,'get_all_methods');
can_ok(__PACKAGE__,'activate_all_languages');
can_ok(__PACKAGE__,'deactivate_all_languages');
can_ok(__PACKAGE__,'get_all_languages');
can_ok(__PACKAGE__,'get_active_languages');
can_ok(__PACKAGE__,'get_inactive_languages');
can_ok(__PACKAGE__,'is_active');
can_ok(__PACKAGE__,'is_valid_language');
can_ok(__PACKAGE__,'activate_language');
can_ok(__PACKAGE__,'deactivate_language');
can_ok(__PACKAGE__,'set_active_languages');
can_ok(__PACKAGE__,'name_of');

