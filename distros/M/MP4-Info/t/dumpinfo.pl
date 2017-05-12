#!perl -w

use MP4::Info;

if (@ARGV != 1)
{
    print "Usage: dumpinfo <mpeg4file>\n";
    exit 1;
}

my $tags = get_mp4tag ($ARGV[0]);
if (!defined ($tags))
{
    print "Can't get MPEG-4 info: $@\n";
    exit 1;
}

foreach my $tag (sort keys %$tags)
{
    if (exists $tags->{$tag}[1])
    {
	print "$tag\t", $tags->{$tag}[0], "/",  $tags->{$tag}[1], "\n";
    }
    elsif ($tag eq 'COVR')
    {
	print "$tag\t",substr($tags->{$tag},0,4),"...\n";
    }
    else
    {
	print "$tag\t", $tags->{$tag}, "\n";
    }
}

# Local Variables:
# eval: (cperl-set-style "BSD")
# End:
