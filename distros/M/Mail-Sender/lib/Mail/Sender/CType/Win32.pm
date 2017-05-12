package Mail::Sender::CType::Win32;
$Mail::Sender::CType::Win32::VERSION = '0.903';
use strict;
use warnings;
use Mail::Sender ();
use Win32API::Registry qw(RegOpenKeyEx KEY_READ HKEY_CLASSES_ROOT RegQueryValueEx);

no warnings 'redefine';

*Mail::Sender::GuessCType = \&GuessCType;
sub GuessCType {
    my $ext = shift;
    $ext =~ s/^.*\././;
    my ($key, $type, $data);
    RegOpenKeyEx(HKEY_CLASSES_ROOT, $ext, 0, KEY_READ, $key)
        or return 'application/octet-stream';
    RegQueryValueEx($key, "Content Type", [], $type, $data, [])
        or return 'application/octet-stream';
    return $data || 'application/octet-stream';
}

1;
__END__

=encoding UTF-8

=head1 NAME

Mail::Sender::CType::Win32 - (DEPRECATED) Alter how we find the MIME type of a file.

=head1 SYNOPSIS

    use Mail::Sender;
    use Mail::Sender::CType::Win32;

    # use the registry to find the MIME Type
    my $type = Mail::Sender::GuessCType("foo.txt");

=head1 DESCRIPTION

This exists solely to change the way you look up MIME types in Windows environments.

=head1 FUNCTIONS

L<Mail::Sender::CType::Win32> makes the following functions available and overrides
the functions in L<Mail::Sender> with these functions as well.

=head2 GuessCType

Guess the MIME type using the Windows registry.

=cut
