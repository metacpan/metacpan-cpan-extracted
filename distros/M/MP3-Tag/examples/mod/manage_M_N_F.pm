use strict;
use Normalize::Text::Music_Fields;
use MP3::Tag;

for (qw(read_composer_file prepare_tag_object_comp normalize_file_lines
	emit_as_mail_header merge_info check_persons test_normalize_piece)) {
  no strict;
  *$_ = \&{"Normalize::Text::Music_Fields::$_"};
}

1;
