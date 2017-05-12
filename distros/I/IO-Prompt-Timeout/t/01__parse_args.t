use strict;
use warnings;
use Test::More;

use IO::Prompt::Timeout;

subtest 'default answer' => sub {
    my $answer = 'yes';
    my %parsed = IO::Prompt::Timeout::_parse_args(default => $answer);
    is($parsed{default_answer}, $answer, 'copied');
};

done_testing;

__END__

# for Emacsen
# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# cperl-close-paren-offset: -4
# cperl-indent-parens-as-block: t
# indent-tabs-mode: nil
# coding: utf-8
# End:

# vi: set ts=4 sw=4 sts=0 et ft=perl fenc=utf-8 ff=unix :
