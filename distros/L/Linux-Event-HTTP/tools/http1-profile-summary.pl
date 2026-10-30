#!/usr/bin/env perl
use v5.36;
use Devel::NYTProf::Data;
use JSON::PP ();

# Development diagnostic only. Inclusive times overlap: never sum them.
my ($file, $requests, $json) = @ARGV;
die "usage: $0 PROFILE TOTAL_REQUESTS [JSON]\n"
    unless defined($file) && defined($requests) && $requests =~ /\A[1-9][0-9]*\z/;
my $profile = Devel::NYTProf::Data->new({ filename => $file, quiet => 1 });
my (@rows, %groups);
my $total = 0;
for my $info (values %{ $profile->subname_subinfo_map }) {
    next unless $info->calls;
    my $name = $info->subname;
    my $group = $name =~ /\AUniform::HTTP/ ? 'Uniform::HTTP'
        : $name =~ /\AUnblock::HTTP1(?:::|\z)/ ? 'Unblock::HTTP1'
        : $name =~ /\AUnblock::HTTP(?:::|\z)/ ? 'Unblock::HTTP'
        : $name =~ /\ALinux::Event::HTTP(?:::|\z)/ ? 'Linux::Event::HTTP'
        : $name =~ /\ALinux::Event(?:::|\z)/ ? 'Linux::Event'
        : 'other';
    my $exclusive = $info->excl_time;
    $total += $exclusive;
    $groups{$group} += $exclusive;
    push @rows, {
        sub => $name, calls => $info->calls,
        calls_per_request => $info->calls / $requests,
        exclusive_seconds => $exclusive,
        inclusive_seconds => $info->incl_time,
    };
}
@rows = sort { $b->{exclusive_seconds} <=> $a->{exclusive_seconds} } @rows;
say "Profiled exclusive subroutine time (instrumented, not throughput):";
for my $group (sort { $groups{$b} <=> $groups{$a} } keys %groups) {
    printf "%6.2f%% %s\n", 100 * $groups{$group} / ($total || 1), $group;
}
say "Top subroutines: exclusive percent, calls/request, name";
for my $row (@rows[0 .. ($#rows < 39 ? $#rows : 39)]) {
    printf "%6.2f%% %8.2f %s\n",
        100 * $row->{exclusive_seconds} / ($total || 1),
        $row->{calls_per_request}, $row->{sub};
}
if (defined $json) {
    open my $fh, '>', $json or die "$json: $!";
    print {$fh} JSON::PP->new->canonical->pretty->encode({
        total_requests => 0 + $requests, nytprof_version => $Devel::NYTProf::Data::VERSION,
        clock => $profile->options->{clock},
        total_exclusive_seconds => $total, groups => \%groups, subroutines => \@rows,
    });
    close $fh or die "$json: $!";
}
