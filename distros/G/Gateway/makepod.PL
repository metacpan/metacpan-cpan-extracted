# makepod.PL -- Generates News/Gateway.pod from individual POD files.
# $Id: makepod.PL,v 0.2 1997/12/23 12:43:17 eagle Exp $

# Assuming that paths are relative to the root of the installation tree,
# create News/Gateway.pod, which will be where we write out our output.
open (POD, '>News/Gateway.pod')
    or die "Cannot create News/Gateway.pod: $!\n";

# We're going to use pod/master.pod as the template, and then insert the
# other POD files in the pod directory at the appropriate place.
open (MASTER, 'pod/master.pod') or die "Cannot open pod/master.pod: $!\n";
while (<MASTER>) {
    if (/^\@\@ (\w+):/) {
        my $list = uc $1;
        open (LIST, "pod/$list") or die "Cannot open pod/.$list: $!\n";
        local $_;
        while (<LIST>) {
            chomp ($pod = $_);
            open (SOURCE, "pod/$pod.pod")
                or die "Cannot open pod/$pod.pod: $!\n";
            print POD while (<SOURCE>);
            close SOURCE;
            print POD "\n" unless eof LIST;
        }
        close LIST;
    } else {
        print POD;
    }
}
