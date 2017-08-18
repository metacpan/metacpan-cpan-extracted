# NAME

List::MoreUtils::XS - Provide compiled List::MoreUtils functions

# SYNOPSIS

    use List::Moreutils::XS ();
    use List::MoreUtils ':all';

    my @procs = get_process_stats->fetchall_array;
    # sort by ppid, then pid
    qsort { $a->[3] <=> $b->[3] or $a->[2] <=> $b->[2] } @procs;
    while( @procs ) {
        my $proc = shift @procs;
        my @children = equal_range { $_->[3] <=> $proc->[2] } @procs;
    }

    my @left = qw(this is a test);
    my @right = qw(this is also a test);
    my %rlinfo = listcmp @left, @right;

    # on unsorted
    my $i = firstidx { $_ eq 'yeah' } @foo;
    # on sorted - always first, but might not be 'yeah'
    my $j = lower_bound { $_ cmp 'yeah' } @bar;
    # on sorted - any of occurrences, is surely 'yeah'
    my $k = bsearchidx { $_ cmp 'yeah' } @bar;

# DESCRIPTION

List::MoreUtils::XS is a backend for List::MoreUtils. Even if it's possible
(because of user wishes) to have it practically independent from
[List::MoreUtils](https://metacpan.org/pod/List::MoreUtils), it technically depend on `List::MoreUtils`. Since it's
only a backend, the API is not public and can change without any warning.

# SEE ALSO

[List::Util](https://metacpan.org/pod/List::Util), [List::AllUtils](https://metacpan.org/pod/List::AllUtils)

# AUTHOR

Jens Rehsack &lt;rehsack AT cpan.org>

Adam Kennedy &lt;adamk@cpan.org>

Tassilo von Parseval &lt;tassilo.von.parseval@rwth-aachen.de>

# COPYRIGHT AND LICENSE

Some parts copyright 2011 Aaron Crane.

Copyright 2004 - 2010 by Tassilo von Parseval

Copyright 2013 - 2017 by Jens Rehsack

All code added with 0.417 or later is licensed under the Apache License,
Version 2.0 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

All code until 0.416 is licensed under the same terms as Perl itself,
either Perl version 5.8.4 or, at your option, any later version of
Perl 5 you may have available.
