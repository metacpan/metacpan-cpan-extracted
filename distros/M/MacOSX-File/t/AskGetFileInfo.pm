#
# $Id: AskGetFileInfo.pm,v 0.70 2005/08/09 15:47:00 dankogai Exp $
#
sub askgetfileinfo{
    my $asked = qx(/Developer/Tools/GetFileInfo $_[0]);
    $asked =~ /^attributes: (\w+)/mi;
    $asked = $1;
    $asked =~ s/z$//io;
    return $asked;
}
1;
