package HTML::Pictogram::MobileJp;
use strict;
use warnings;
use 5.00800;
our $VERSION = '0.02';
use HTML::Pictogram::MobileJp::EmojiNumber;

# backward compatibility
sub convert { HTML::Pictogram::MobileJp::EmojiNumber::convert(@_) }

1;
__END__

=encoding utf8

=head1 NAME

HTML::Pictogram::MobileJp - Convert pictograms in HTML

=head1 DESCRIPTION

ドコモの絵文字番号 or 絵文字Unicodeの実態参照でかけば、それを各キャリアでみれるように変換するというライブラリです。

詳細は L<HTML::Pictogram::MobileJp::EmojiNumber>, L<HTML::Pictogram::MobileJp::Unicode> をそれぞれみてください。

=head1 AUTHOR

Tokuhiro Matsuno (tokuhirom@gmail.com)

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify            it under the same terms as Perl itself.

=cut
