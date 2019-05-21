package MPMinus::Skel::REST; # $Id: REST.pm 280 2019-05-14 06:47:06Z minus $
use strict;
use utf8;

=encoding utf8

=head1 NAME

MPMinus::Skel::REST - Internal helper's methods for MPMinus::Skel

=head1 VIRSION

Version 1.00

=head1 SYNOPSIS

none

=head1 DESCRIPTION

Internal helper's methods for MPMinus::Skel

no public methods

=head2 build, dirs, pool

Main methods. For internal use only

=head1 SEE ALSO

L<MPMinus::Skel>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use constant SIGNATURE => "rest";

use vars qw($VERSION);
$VERSION = '1.00';

sub build {
    my $self = shift;

    my $rplc = $self->{rplc};

    # END signature
    $rplc->{ENDSIGN} = "__END__";

    $rplc->{TODO} = "TODO";

    $self->maybe::next::method();
    return 1;
}
sub dirs {
    my $self = shift;
    $self->{subdirs}{(SIGNATURE)} = [
        {
            path => 'lib/MPM',
            mode => 0755,
        },
        {
            path => 'src',
            mode => 0755,
        },
        {
            path => 't',
            mode => 0755,
        },
    ];
    $self->maybe::next::method();
    return 1;
}
sub pool {
    my $self = shift;
    my $pos =  tell DATA;
    my $data = scalar(do { local $/; <DATA> });
    seek DATA, $pos, 0;
    $self->{pools}{(SIGNATURE)} = $data;
    $self->maybe::next::method();
    return 1;
}

1;
__DATA__

-----BEGIN FILE-----
Name: Changes
File: Changes
Mode: 644

# Version/Revision history for MPM::%PROJECT_NAME%.
# %DOLLAR%Id%DOLLAR%

%PROJECT_VERSION% %GMT%
   * Initial release

-----END FILE-----

-----BEGIN FILE-----
Name: INSTALL
File: INSTALL
Mode: 644

INSTALLATION INSTRUCTIONS

    perl Makefile.PL
    make
    make test
    make install
    make clean

    # Copy config-file to Apache configuration directory, e.g:
    #   cp src/%PROJECT_NAMEL%_apache2.conf %HTTPD_ROOT%/conf.d

    apachectl restart

-----END FILE-----

-----BEGIN FILE-----
Name: LICENSE
File: LICENSE
Mode: 644
Encode: base64

VGVybXMgb2YgUGVybCBpdHNlbGYKCmEpIHRoZSBHTlUgR2VuZXJhbCBQdWJsaWMgTGljZW5zZSBh
cyBwdWJsaXNoZWQgYnkgdGhlIEZyZWUKICAgU29mdHdhcmUgRm91bmRhdGlvbjsgZWl0aGVyIHZl
cnNpb24gMSwgb3IgKGF0IHlvdXIgb3B0aW9uKSBhbnkKICAgbGF0ZXIgdmVyc2lvbiwgb3IKYikg
dGhlICJBcnRpc3RpYyBMaWNlbnNlIgoKLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQoKVGhlIEdlbmVyYWwg
UHVibGljIExpY2Vuc2UgKEdQTCkKVmVyc2lvbiAyLCBKdW5lIDE5OTEKCkNvcHlyaWdodCAoQykg
MTk4OSwgMTk5MSBGcmVlIFNvZnR3YXJlIEZvdW5kYXRpb24sIEluYy4gNjc1IE1hc3MgQXZlLApD
YW1icmlkZ2UsIE1BIDAyMTM5LCBVU0EuIEV2ZXJ5b25lIGlzIHBlcm1pdHRlZCB0byBjb3B5IGFu
ZCBkaXN0cmlidXRlCnZlcmJhdGltIGNvcGllcyBvZiB0aGlzIGxpY2Vuc2UgZG9jdW1lbnQsIGJ1
dCBjaGFuZ2luZyBpdCBpcyBub3QgYWxsb3dlZC4KClByZWFtYmxlCgpUaGUgbGljZW5zZXMgZm9y
IG1vc3Qgc29mdHdhcmUgYXJlIGRlc2lnbmVkIHRvIHRha2UgYXdheSB5b3VyIGZyZWVkb20gdG8g
c2hhcmUKYW5kIGNoYW5nZSBpdC4gQnkgY29udHJhc3QsIHRoZSBHTlUgR2VuZXJhbCBQdWJsaWMg
TGljZW5zZSBpcyBpbnRlbmRlZCB0bwpndWFyYW50ZWUgeW91ciBmcmVlZG9tIHRvIHNoYXJlIGFu
ZCBjaGFuZ2UgZnJlZSBzb2Z0d2FyZS0tdG8gbWFrZSBzdXJlIHRoZQpzb2Z0d2FyZSBpcyBmcmVl
IGZvciBhbGwgaXRzIHVzZXJzLiBUaGlzIEdlbmVyYWwgUHVibGljIExpY2Vuc2UgYXBwbGllcyB0
byBtb3N0IG9mCnRoZSBGcmVlIFNvZnR3YXJlIEZvdW5kYXRpb24ncyBzb2Z0d2FyZSBhbmQgdG8g
YW55IG90aGVyIHByb2dyYW0gd2hvc2UKYXV0aG9ycyBjb21taXQgdG8gdXNpbmcgaXQuIChTb21l
IG90aGVyIEZyZWUgU29mdHdhcmUgRm91bmRhdGlvbiBzb2Z0d2FyZSBpcwpjb3ZlcmVkIGJ5IHRo
ZSBHTlUgTGlicmFyeSBHZW5lcmFsIFB1YmxpYyBMaWNlbnNlIGluc3RlYWQuKSBZb3UgY2FuIGFw
cGx5IGl0IHRvCnlvdXIgcHJvZ3JhbXMsIHRvby4KCldoZW4gd2Ugc3BlYWsgb2YgZnJlZSBzb2Z0
d2FyZSwgd2UgYXJlIHJlZmVycmluZyB0byBmcmVlZG9tLCBub3QgcHJpY2UuIE91cgpHZW5lcmFs
IFB1YmxpYyBMaWNlbnNlcyBhcmUgZGVzaWduZWQgdG8gbWFrZSBzdXJlIHRoYXQgeW91IGhhdmUg
dGhlIGZyZWVkb20KdG8gZGlzdHJpYnV0ZSBjb3BpZXMgb2YgZnJlZSBzb2Z0d2FyZSAoYW5kIGNo
YXJnZSBmb3IgdGhpcyBzZXJ2aWNlIGlmIHlvdSB3aXNoKSwgdGhhdAp5b3UgcmVjZWl2ZSBzb3Vy
Y2UgY29kZSBvciBjYW4gZ2V0IGl0IGlmIHlvdSB3YW50IGl0LCB0aGF0IHlvdSBjYW4gY2hhbmdl
IHRoZQpzb2Z0d2FyZSBvciB1c2UgcGllY2VzIG9mIGl0IGluIG5ldyBmcmVlIHByb2dyYW1zOyBh
bmQgdGhhdCB5b3Uga25vdyB5b3UgY2FuIGRvCnRoZXNlIHRoaW5ncy4KClRvIHByb3RlY3QgeW91
ciByaWdodHMsIHdlIG5lZWQgdG8gbWFrZSByZXN0cmljdGlvbnMgdGhhdCBmb3JiaWQgYW55b25l
IHRvIGRlbnkKeW91IHRoZXNlIHJpZ2h0cyBvciB0byBhc2sgeW91IHRvIHN1cnJlbmRlciB0aGUg
cmlnaHRzLiBUaGVzZSByZXN0cmljdGlvbnMKdHJhbnNsYXRlIHRvIGNlcnRhaW4gcmVzcG9uc2li
aWxpdGllcyBmb3IgeW91IGlmIHlvdSBkaXN0cmlidXRlIGNvcGllcyBvZiB0aGUKc29mdHdhcmUs
IG9yIGlmIHlvdSBtb2RpZnkgaXQuCgpGb3IgZXhhbXBsZSwgaWYgeW91IGRpc3RyaWJ1dGUgY29w
aWVzIG9mIHN1Y2ggYSBwcm9ncmFtLCB3aGV0aGVyIGdyYXRpcyBvciBmb3IgYQpmZWUsIHlvdSBt
dXN0IGdpdmUgdGhlIHJlY2lwaWVudHMgYWxsIHRoZSByaWdodHMgdGhhdCB5b3UgaGF2ZS4gWW91
IG11c3QgbWFrZQpzdXJlIHRoYXQgdGhleSwgdG9vLCByZWNlaXZlIG9yIGNhbiBnZXQgdGhlIHNv
dXJjZSBjb2RlLiBBbmQgeW91IG11c3Qgc2hvdwp0aGVtIHRoZXNlIHRlcm1zIHNvIHRoZXkga25v
dyB0aGVpciByaWdodHMuCgpXZSBwcm90ZWN0IHlvdXIgcmlnaHRzIHdpdGggdHdvIHN0ZXBzOiAo
MSkgY29weXJpZ2h0IHRoZSBzb2Z0d2FyZSwgYW5kICgyKSBvZmZlcgp5b3UgdGhpcyBsaWNlbnNl
IHdoaWNoIGdpdmVzIHlvdSBsZWdhbCBwZXJtaXNzaW9uIHRvIGNvcHksIGRpc3RyaWJ1dGUgYW5k
L29yCm1vZGlmeSB0aGUgc29mdHdhcmUuCgpBbHNvLCBmb3IgZWFjaCBhdXRob3IncyBwcm90ZWN0
aW9uIGFuZCBvdXJzLCB3ZSB3YW50IHRvIG1ha2UgY2VydGFpbiB0aGF0CmV2ZXJ5b25lIHVuZGVy
c3RhbmRzIHRoYXQgdGhlcmUgaXMgbm8gd2FycmFudHkgZm9yIHRoaXMgZnJlZSBzb2Z0d2FyZS4g
SWYgdGhlCnNvZnR3YXJlIGlzIG1vZGlmaWVkIGJ5IHNvbWVvbmUgZWxzZSBhbmQgcGFzc2VkIG9u
LCB3ZSB3YW50IGl0cyByZWNpcGllbnRzIHRvCmtub3cgdGhhdCB3aGF0IHRoZXkgaGF2ZSBpcyBu
b3QgdGhlIG9yaWdpbmFsLCBzbyB0aGF0IGFueSBwcm9ibGVtcyBpbnRyb2R1Y2VkIGJ5Cm90aGVy
cyB3aWxsIG5vdCByZWZsZWN0IG9uIHRoZSBvcmlnaW5hbCBhdXRob3JzJyByZXB1dGF0aW9ucy4K
CkZpbmFsbHksIGFueSBmcmVlIHByb2dyYW0gaXMgdGhyZWF0ZW5lZCBjb25zdGFudGx5IGJ5IHNv
ZnR3YXJlIHBhdGVudHMuIFdlIHdpc2gKdG8gYXZvaWQgdGhlIGRhbmdlciB0aGF0IHJlZGlzdHJp
YnV0b3JzIG9mIGEgZnJlZSBwcm9ncmFtIHdpbGwgaW5kaXZpZHVhbGx5IG9idGFpbgpwYXRlbnQg
bGljZW5zZXMsIGluIGVmZmVjdCBtYWtpbmcgdGhlIHByb2dyYW0gcHJvcHJpZXRhcnkuIFRvIHBy
ZXZlbnQgdGhpcywgd2UKaGF2ZSBtYWRlIGl0IGNsZWFyIHRoYXQgYW55IHBhdGVudCBtdXN0IGJl
IGxpY2Vuc2VkIGZvciBldmVyeW9uZSdzIGZyZWUgdXNlIG9yCm5vdCBsaWNlbnNlZCBhdCBhbGwu
CgpUaGUgcHJlY2lzZSB0ZXJtcyBhbmQgY29uZGl0aW9ucyBmb3IgY29weWluZywgZGlzdHJpYnV0
aW9uIGFuZCBtb2RpZmljYXRpb24KZm9sbG93LgoKR05VIEdFTkVSQUwgUFVCTElDIExJQ0VOU0UK
VEVSTVMgQU5EIENPTkRJVElPTlMgRk9SIENPUFlJTkcsIERJU1RSSUJVVElPTiBBTkQKTU9ESUZJ
Q0FUSU9OCgowLiBUaGlzIExpY2Vuc2UgYXBwbGllcyB0byBhbnkgcHJvZ3JhbSBvciBvdGhlciB3
b3JrIHdoaWNoIGNvbnRhaW5zIGEgbm90aWNlCnBsYWNlZCBieSB0aGUgY29weXJpZ2h0IGhvbGRl
ciBzYXlpbmcgaXQgbWF5IGJlIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSB0ZXJtcyBvZgp0aGlzIEdl
bmVyYWwgUHVibGljIExpY2Vuc2UuIFRoZSAiUHJvZ3JhbSIsIGJlbG93LCByZWZlcnMgdG8gYW55
IHN1Y2ggcHJvZ3JhbQpvciB3b3JrLCBhbmQgYSAid29yayBiYXNlZCBvbiB0aGUgUHJvZ3JhbSIg
bWVhbnMgZWl0aGVyIHRoZSBQcm9ncmFtIG9yIGFueQpkZXJpdmF0aXZlIHdvcmsgdW5kZXIgY29w
eXJpZ2h0IGxhdzogdGhhdCBpcyB0byBzYXksIGEgd29yayBjb250YWluaW5nIHRoZQpQcm9ncmFt
IG9yIGEgcG9ydGlvbiBvZiBpdCwgZWl0aGVyIHZlcmJhdGltIG9yIHdpdGggbW9kaWZpY2F0aW9u
cyBhbmQvb3IgdHJhbnNsYXRlZAppbnRvIGFub3RoZXIgbGFuZ3VhZ2UuIChIZXJlaW5hZnRlciwg
dHJhbnNsYXRpb24gaXMgaW5jbHVkZWQgd2l0aG91dCBsaW1pdGF0aW9uIGluCnRoZSB0ZXJtICJt
b2RpZmljYXRpb24iLikgRWFjaCBsaWNlbnNlZSBpcyBhZGRyZXNzZWQgYXMgInlvdSIuCgpBY3Rp
dml0aWVzIG90aGVyIHRoYW4gY29weWluZywgZGlzdHJpYnV0aW9uIGFuZCBtb2RpZmljYXRpb24g
YXJlIG5vdCBjb3ZlcmVkIGJ5CnRoaXMgTGljZW5zZTsgdGhleSBhcmUgb3V0c2lkZSBpdHMgc2Nv
cGUuIFRoZSBhY3Qgb2YgcnVubmluZyB0aGUgUHJvZ3JhbSBpcyBub3QKcmVzdHJpY3RlZCwgYW5k
IHRoZSBvdXRwdXQgZnJvbSB0aGUgUHJvZ3JhbSBpcyBjb3ZlcmVkIG9ubHkgaWYgaXRzIGNvbnRl
bnRzCmNvbnN0aXR1dGUgYSB3b3JrIGJhc2VkIG9uIHRoZSBQcm9ncmFtIChpbmRlcGVuZGVudCBv
ZiBoYXZpbmcgYmVlbiBtYWRlIGJ5CnJ1bm5pbmcgdGhlIFByb2dyYW0pLiBXaGV0aGVyIHRoYXQg
aXMgdHJ1ZSBkZXBlbmRzIG9uIHdoYXQgdGhlIFByb2dyYW0gZG9lcy4KCjEuIFlvdSBtYXkgY29w
eSBhbmQgZGlzdHJpYnV0ZSB2ZXJiYXRpbSBjb3BpZXMgb2YgdGhlIFByb2dyYW0ncyBzb3VyY2Ug
Y29kZSBhcwp5b3UgcmVjZWl2ZSBpdCwgaW4gYW55IG1lZGl1bSwgcHJvdmlkZWQgdGhhdCB5b3Ug
Y29uc3BpY3VvdXNseSBhbmQgYXBwcm9wcmlhdGVseQpwdWJsaXNoIG9uIGVhY2ggY29weSBhbiBh
cHByb3ByaWF0ZSBjb3B5cmlnaHQgbm90aWNlIGFuZCBkaXNjbGFpbWVyIG9mIHdhcnJhbnR5Owpr
ZWVwIGludGFjdCBhbGwgdGhlIG5vdGljZXMgdGhhdCByZWZlciB0byB0aGlzIExpY2Vuc2UgYW5k
IHRvIHRoZSBhYnNlbmNlIG9mIGFueQp3YXJyYW50eTsgYW5kIGdpdmUgYW55IG90aGVyIHJlY2lw
aWVudHMgb2YgdGhlIFByb2dyYW0gYSBjb3B5IG9mIHRoaXMgTGljZW5zZQphbG9uZyB3aXRoIHRo
ZSBQcm9ncmFtLgoKWW91IG1heSBjaGFyZ2UgYSBmZWUgZm9yIHRoZSBwaHlzaWNhbCBhY3Qgb2Yg
dHJhbnNmZXJyaW5nIGEgY29weSwgYW5kIHlvdSBtYXkgYXQKeW91ciBvcHRpb24gb2ZmZXIgd2Fy
cmFudHkgcHJvdGVjdGlvbiBpbiBleGNoYW5nZSBmb3IgYSBmZWUuCgoyLiBZb3UgbWF5IG1vZGlm
eSB5b3VyIGNvcHkgb3IgY29waWVzIG9mIHRoZSBQcm9ncmFtIG9yIGFueSBwb3J0aW9uIG9mIGl0
LCB0aHVzCmZvcm1pbmcgYSB3b3JrIGJhc2VkIG9uIHRoZSBQcm9ncmFtLCBhbmQgY29weSBhbmQg
ZGlzdHJpYnV0ZSBzdWNoCm1vZGlmaWNhdGlvbnMgb3Igd29yayB1bmRlciB0aGUgdGVybXMgb2Yg
U2VjdGlvbiAxIGFib3ZlLCBwcm92aWRlZCB0aGF0IHlvdSBhbHNvCm1lZXQgYWxsIG9mIHRoZXNl
IGNvbmRpdGlvbnM6CgphKSBZb3UgbXVzdCBjYXVzZSB0aGUgbW9kaWZpZWQgZmlsZXMgdG8gY2Fy
cnkgcHJvbWluZW50IG5vdGljZXMgc3RhdGluZyB0aGF0IHlvdQpjaGFuZ2VkIHRoZSBmaWxlcyBh
bmQgdGhlIGRhdGUgb2YgYW55IGNoYW5nZS4KCmIpIFlvdSBtdXN0IGNhdXNlIGFueSB3b3JrIHRo
YXQgeW91IGRpc3RyaWJ1dGUgb3IgcHVibGlzaCwgdGhhdCBpbiB3aG9sZSBvciBpbgpwYXJ0IGNv
bnRhaW5zIG9yIGlzIGRlcml2ZWQgZnJvbSB0aGUgUHJvZ3JhbSBvciBhbnkgcGFydCB0aGVyZW9m
LCB0byBiZSBsaWNlbnNlZAphcyBhIHdob2xlIGF0IG5vIGNoYXJnZSB0byBhbGwgdGhpcmQgcGFy
dGllcyB1bmRlciB0aGUgdGVybXMgb2YgdGhpcyBMaWNlbnNlLgoKYykgSWYgdGhlIG1vZGlmaWVk
IHByb2dyYW0gbm9ybWFsbHkgcmVhZHMgY29tbWFuZHMgaW50ZXJhY3RpdmVseSB3aGVuIHJ1biwg
eW91Cm11c3QgY2F1c2UgaXQsIHdoZW4gc3RhcnRlZCBydW5uaW5nIGZvciBzdWNoIGludGVyYWN0
aXZlIHVzZSBpbiB0aGUgbW9zdCBvcmRpbmFyeQp3YXksIHRvIHByaW50IG9yIGRpc3BsYXkgYW4g
YW5ub3VuY2VtZW50IGluY2x1ZGluZyBhbiBhcHByb3ByaWF0ZSBjb3B5cmlnaHQKbm90aWNlIGFu
ZCBhIG5vdGljZSB0aGF0IHRoZXJlIGlzIG5vIHdhcnJhbnR5IChvciBlbHNlLCBzYXlpbmcgdGhh
dCB5b3UgcHJvdmlkZSBhCndhcnJhbnR5KSBhbmQgdGhhdCB1c2VycyBtYXkgcmVkaXN0cmlidXRl
IHRoZSBwcm9ncmFtIHVuZGVyIHRoZXNlIGNvbmRpdGlvbnMsCmFuZCB0ZWxsaW5nIHRoZSB1c2Vy
IGhvdyB0byB2aWV3IGEgY29weSBvZiB0aGlzIExpY2Vuc2UuIChFeGNlcHRpb246IGlmIHRoZQpQ
cm9ncmFtIGl0c2VsZiBpcyBpbnRlcmFjdGl2ZSBidXQgZG9lcyBub3Qgbm9ybWFsbHkgcHJpbnQg
c3VjaCBhbiBhbm5vdW5jZW1lbnQsCnlvdXIgd29yayBiYXNlZCBvbiB0aGUgUHJvZ3JhbSBpcyBu
b3QgcmVxdWlyZWQgdG8gcHJpbnQgYW4gYW5ub3VuY2VtZW50LikKClRoZXNlIHJlcXVpcmVtZW50
cyBhcHBseSB0byB0aGUgbW9kaWZpZWQgd29yayBhcyBhIHdob2xlLiBJZiBpZGVudGlmaWFibGUK
c2VjdGlvbnMgb2YgdGhhdCB3b3JrIGFyZSBub3QgZGVyaXZlZCBmcm9tIHRoZSBQcm9ncmFtLCBh
bmQgY2FuIGJlIHJlYXNvbmFibHkKY29uc2lkZXJlZCBpbmRlcGVuZGVudCBhbmQgc2VwYXJhdGUg
d29ya3MgaW4gdGhlbXNlbHZlcywgdGhlbiB0aGlzIExpY2Vuc2UsCmFuZCBpdHMgdGVybXMsIGRv
IG5vdCBhcHBseSB0byB0aG9zZSBzZWN0aW9ucyB3aGVuIHlvdSBkaXN0cmlidXRlIHRoZW0gYXMK
c2VwYXJhdGUgd29ya3MuIEJ1dCB3aGVuIHlvdSBkaXN0cmlidXRlIHRoZSBzYW1lIHNlY3Rpb25z
IGFzIHBhcnQgb2YgYSB3aG9sZQp3aGljaCBpcyBhIHdvcmsgYmFzZWQgb24gdGhlIFByb2dyYW0s
IHRoZSBkaXN0cmlidXRpb24gb2YgdGhlIHdob2xlIG11c3QgYmUgb24KdGhlIHRlcm1zIG9mIHRo
aXMgTGljZW5zZSwgd2hvc2UgcGVybWlzc2lvbnMgZm9yIG90aGVyIGxpY2Vuc2VlcyBleHRlbmQg
dG8gdGhlCmVudGlyZSB3aG9sZSwgYW5kIHRodXMgdG8gZWFjaCBhbmQgZXZlcnkgcGFydCByZWdh
cmRsZXNzIG9mIHdobyB3cm90ZSBpdC4KClRodXMsIGl0IGlzIG5vdCB0aGUgaW50ZW50IG9mIHRo
aXMgc2VjdGlvbiB0byBjbGFpbSByaWdodHMgb3IgY29udGVzdCB5b3VyIHJpZ2h0cyB0bwp3b3Jr
IHdyaXR0ZW4gZW50aXJlbHkgYnkgeW91OyByYXRoZXIsIHRoZSBpbnRlbnQgaXMgdG8gZXhlcmNp
c2UgdGhlIHJpZ2h0IHRvIGNvbnRyb2wKdGhlIGRpc3RyaWJ1dGlvbiBvZiBkZXJpdmF0aXZlIG9y
IGNvbGxlY3RpdmUgd29ya3MgYmFzZWQgb24gdGhlIFByb2dyYW0uCgpJbiBhZGRpdGlvbiwgbWVy
ZSBhZ2dyZWdhdGlvbiBvZiBhbm90aGVyIHdvcmsgbm90IGJhc2VkIG9uIHRoZSBQcm9ncmFtIHdp
dGggdGhlClByb2dyYW0gKG9yIHdpdGggYSB3b3JrIGJhc2VkIG9uIHRoZSBQcm9ncmFtKSBvbiBh
IHZvbHVtZSBvZiBhIHN0b3JhZ2Ugb3IKZGlzdHJpYnV0aW9uIG1lZGl1bSBkb2VzIG5vdCBicmlu
ZyB0aGUgb3RoZXIgd29yayB1bmRlciB0aGUgc2NvcGUgb2YgdGhpcwpMaWNlbnNlLgoKMy4gWW91
IG1heSBjb3B5IGFuZCBkaXN0cmlidXRlIHRoZSBQcm9ncmFtIChvciBhIHdvcmsgYmFzZWQgb24g
aXQsIHVuZGVyClNlY3Rpb24gMikgaW4gb2JqZWN0IGNvZGUgb3IgZXhlY3V0YWJsZSBmb3JtIHVu
ZGVyIHRoZSB0ZXJtcyBvZiBTZWN0aW9ucyAxIGFuZCAyCmFib3ZlIHByb3ZpZGVkIHRoYXQgeW91
IGFsc28gZG8gb25lIG9mIHRoZSBmb2xsb3dpbmc6CgphKSBBY2NvbXBhbnkgaXQgd2l0aCB0aGUg
Y29tcGxldGUgY29ycmVzcG9uZGluZyBtYWNoaW5lLXJlYWRhYmxlIHNvdXJjZQpjb2RlLCB3aGlj
aCBtdXN0IGJlIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSB0ZXJtcyBvZiBTZWN0aW9ucyAxIGFuZCAy
IGFib3ZlIG9uIGEKbWVkaXVtIGN1c3RvbWFyaWx5IHVzZWQgZm9yIHNvZnR3YXJlIGludGVyY2hh
bmdlOyBvciwKCmIpIEFjY29tcGFueSBpdCB3aXRoIGEgd3JpdHRlbiBvZmZlciwgdmFsaWQgZm9y
IGF0IGxlYXN0IHRocmVlIHllYXJzLCB0byBnaXZlIGFueQp0aGlyZCBwYXJ0eSwgZm9yIGEgY2hh
cmdlIG5vIG1vcmUgdGhhbiB5b3VyIGNvc3Qgb2YgcGh5c2ljYWxseSBwZXJmb3JtaW5nIHNvdXJj
ZQpkaXN0cmlidXRpb24sIGEgY29tcGxldGUgbWFjaGluZS1yZWFkYWJsZSBjb3B5IG9mIHRoZSBj
b3JyZXNwb25kaW5nIHNvdXJjZQpjb2RlLCB0byBiZSBkaXN0cmlidXRlZCB1bmRlciB0aGUgdGVy
bXMgb2YgU2VjdGlvbnMgMSBhbmQgMiBhYm92ZSBvbiBhIG1lZGl1bQpjdXN0b21hcmlseSB1c2Vk
IGZvciBzb2Z0d2FyZSBpbnRlcmNoYW5nZTsgb3IsCgpjKSBBY2NvbXBhbnkgaXQgd2l0aCB0aGUg
aW5mb3JtYXRpb24geW91IHJlY2VpdmVkIGFzIHRvIHRoZSBvZmZlciB0byBkaXN0cmlidXRlCmNv
cnJlc3BvbmRpbmcgc291cmNlIGNvZGUuIChUaGlzIGFsdGVybmF0aXZlIGlzIGFsbG93ZWQgb25s
eSBmb3Igbm9uY29tbWVyY2lhbApkaXN0cmlidXRpb24gYW5kIG9ubHkgaWYgeW91IHJlY2VpdmVk
IHRoZSBwcm9ncmFtIGluIG9iamVjdCBjb2RlIG9yIGV4ZWN1dGFibGUKZm9ybSB3aXRoIHN1Y2gg
YW4gb2ZmZXIsIGluIGFjY29yZCB3aXRoIFN1YnNlY3Rpb24gYiBhYm92ZS4pCgpUaGUgc291cmNl
IGNvZGUgZm9yIGEgd29yayBtZWFucyB0aGUgcHJlZmVycmVkIGZvcm0gb2YgdGhlIHdvcmsgZm9y
IG1ha2luZwptb2RpZmljYXRpb25zIHRvIGl0LiBGb3IgYW4gZXhlY3V0YWJsZSB3b3JrLCBjb21w
bGV0ZSBzb3VyY2UgY29kZSBtZWFucyBhbGwgdGhlCnNvdXJjZSBjb2RlIGZvciBhbGwgbW9kdWxl
cyBpdCBjb250YWlucywgcGx1cyBhbnkgYXNzb2NpYXRlZCBpbnRlcmZhY2UgZGVmaW5pdGlvbgpm
aWxlcywgcGx1cyB0aGUgc2NyaXB0cyB1c2VkIHRvIGNvbnRyb2wgY29tcGlsYXRpb24gYW5kIGlu
c3RhbGxhdGlvbiBvZiB0aGUKZXhlY3V0YWJsZS4gSG93ZXZlciwgYXMgYSBzcGVjaWFsIGV4Y2Vw
dGlvbiwgdGhlIHNvdXJjZSBjb2RlIGRpc3RyaWJ1dGVkIG5lZWQKbm90IGluY2x1ZGUgYW55dGhp
bmcgdGhhdCBpcyBub3JtYWxseSBkaXN0cmlidXRlZCAoaW4gZWl0aGVyIHNvdXJjZSBvciBiaW5h
cnkgZm9ybSkKd2l0aCB0aGUgbWFqb3IgY29tcG9uZW50cyAoY29tcGlsZXIsIGtlcm5lbCwgYW5k
IHNvIG9uKSBvZiB0aGUgb3BlcmF0aW5nIHN5c3RlbQpvbiB3aGljaCB0aGUgZXhlY3V0YWJsZSBy
dW5zLCB1bmxlc3MgdGhhdCBjb21wb25lbnQgaXRzZWxmIGFjY29tcGFuaWVzIHRoZQpleGVjdXRh
YmxlLgoKSWYgZGlzdHJpYnV0aW9uIG9mIGV4ZWN1dGFibGUgb3Igb2JqZWN0IGNvZGUgaXMgbWFk
ZSBieSBvZmZlcmluZyBhY2Nlc3MgdG8gY29weQpmcm9tIGEgZGVzaWduYXRlZCBwbGFjZSwgdGhl
biBvZmZlcmluZyBlcXVpdmFsZW50IGFjY2VzcyB0byBjb3B5IHRoZSBzb3VyY2UKY29kZSBmcm9t
IHRoZSBzYW1lIHBsYWNlIGNvdW50cyBhcyBkaXN0cmlidXRpb24gb2YgdGhlIHNvdXJjZSBjb2Rl
LCBldmVuIHRob3VnaAp0aGlyZCBwYXJ0aWVzIGFyZSBub3QgY29tcGVsbGVkIHRvIGNvcHkgdGhl
IHNvdXJjZSBhbG9uZyB3aXRoIHRoZSBvYmplY3QgY29kZS4KCjQuIFlvdSBtYXkgbm90IGNvcHks
IG1vZGlmeSwgc3VibGljZW5zZSwgb3IgZGlzdHJpYnV0ZSB0aGUgUHJvZ3JhbSBleGNlcHQgYXMK
ZXhwcmVzc2x5IHByb3ZpZGVkIHVuZGVyIHRoaXMgTGljZW5zZS4gQW55IGF0dGVtcHQgb3RoZXJ3
aXNlIHRvIGNvcHksIG1vZGlmeSwKc3VibGljZW5zZSBvciBkaXN0cmlidXRlIHRoZSBQcm9ncmFt
IGlzIHZvaWQsIGFuZCB3aWxsIGF1dG9tYXRpY2FsbHkgdGVybWluYXRlCnlvdXIgcmlnaHRzIHVu
ZGVyIHRoaXMgTGljZW5zZS4gSG93ZXZlciwgcGFydGllcyB3aG8gaGF2ZSByZWNlaXZlZCBjb3Bp
ZXMsIG9yCnJpZ2h0cywgZnJvbSB5b3UgdW5kZXIgdGhpcyBMaWNlbnNlIHdpbGwgbm90IGhhdmUg
dGhlaXIgbGljZW5zZXMgdGVybWluYXRlZCBzbyBsb25nCmFzIHN1Y2ggcGFydGllcyByZW1haW4g
aW4gZnVsbCBjb21wbGlhbmNlLgoKNS4gWW91IGFyZSBub3QgcmVxdWlyZWQgdG8gYWNjZXB0IHRo
aXMgTGljZW5zZSwgc2luY2UgeW91IGhhdmUgbm90IHNpZ25lZCBpdC4KSG93ZXZlciwgbm90aGlu
ZyBlbHNlIGdyYW50cyB5b3UgcGVybWlzc2lvbiB0byBtb2RpZnkgb3IgZGlzdHJpYnV0ZSB0aGUg
UHJvZ3JhbQpvciBpdHMgZGVyaXZhdGl2ZSB3b3Jrcy4gVGhlc2UgYWN0aW9ucyBhcmUgcHJvaGli
aXRlZCBieSBsYXcgaWYgeW91IGRvIG5vdCBhY2NlcHQKdGhpcyBMaWNlbnNlLiBUaGVyZWZvcmUs
IGJ5IG1vZGlmeWluZyBvciBkaXN0cmlidXRpbmcgdGhlIFByb2dyYW0gKG9yIGFueSB3b3JrCmJh
c2VkIG9uIHRoZSBQcm9ncmFtKSwgeW91IGluZGljYXRlIHlvdXIgYWNjZXB0YW5jZSBvZiB0aGlz
IExpY2Vuc2UgdG8gZG8gc28sCmFuZCBhbGwgaXRzIHRlcm1zIGFuZCBjb25kaXRpb25zIGZvciBj
b3B5aW5nLCBkaXN0cmlidXRpbmcgb3IgbW9kaWZ5aW5nIHRoZQpQcm9ncmFtIG9yIHdvcmtzIGJh
c2VkIG9uIGl0LgoKNi4gRWFjaCB0aW1lIHlvdSByZWRpc3RyaWJ1dGUgdGhlIFByb2dyYW0gKG9y
IGFueSB3b3JrIGJhc2VkIG9uIHRoZSBQcm9ncmFtKSwKdGhlIHJlY2lwaWVudCBhdXRvbWF0aWNh
bGx5IHJlY2VpdmVzIGEgbGljZW5zZSBmcm9tIHRoZSBvcmlnaW5hbCBsaWNlbnNvciB0byBjb3B5
LApkaXN0cmlidXRlIG9yIG1vZGlmeSB0aGUgUHJvZ3JhbSBzdWJqZWN0IHRvIHRoZXNlIHRlcm1z
IGFuZCBjb25kaXRpb25zLiBZb3UKbWF5IG5vdCBpbXBvc2UgYW55IGZ1cnRoZXIgcmVzdHJpY3Rp
b25zIG9uIHRoZSByZWNpcGllbnRzJyBleGVyY2lzZSBvZiB0aGUgcmlnaHRzCmdyYW50ZWQgaGVy
ZWluLiBZb3UgYXJlIG5vdCByZXNwb25zaWJsZSBmb3IgZW5mb3JjaW5nIGNvbXBsaWFuY2UgYnkg
dGhpcmQgcGFydGllcwp0byB0aGlzIExpY2Vuc2UuCgo3LiBJZiwgYXMgYSBjb25zZXF1ZW5jZSBv
ZiBhIGNvdXJ0IGp1ZGdtZW50IG9yIGFsbGVnYXRpb24gb2YgcGF0ZW50IGluZnJpbmdlbWVudApv
ciBmb3IgYW55IG90aGVyIHJlYXNvbiAobm90IGxpbWl0ZWQgdG8gcGF0ZW50IGlzc3VlcyksIGNv
bmRpdGlvbnMgYXJlIGltcG9zZWQgb24KeW91ICh3aGV0aGVyIGJ5IGNvdXJ0IG9yZGVyLCBhZ3Jl
ZW1lbnQgb3Igb3RoZXJ3aXNlKSB0aGF0IGNvbnRyYWRpY3QgdGhlCmNvbmRpdGlvbnMgb2YgdGhp
cyBMaWNlbnNlLCB0aGV5IGRvIG5vdCBleGN1c2UgeW91IGZyb20gdGhlIGNvbmRpdGlvbnMgb2Yg
dGhpcwpMaWNlbnNlLiBJZiB5b3UgY2Fubm90IGRpc3RyaWJ1dGUgc28gYXMgdG8gc2F0aXNmeSBz
aW11bHRhbmVvdXNseSB5b3VyIG9ibGlnYXRpb25zCnVuZGVyIHRoaXMgTGljZW5zZSBhbmQgYW55
IG90aGVyIHBlcnRpbmVudCBvYmxpZ2F0aW9ucywgdGhlbiBhcyBhIGNvbnNlcXVlbmNlCnlvdSBt
YXkgbm90IGRpc3RyaWJ1dGUgdGhlIFByb2dyYW0gYXQgYWxsLiBGb3IgZXhhbXBsZSwgaWYgYSBw
YXRlbnQgbGljZW5zZSB3b3VsZApub3QgcGVybWl0IHJveWFsdHktZnJlZSByZWRpc3RyaWJ1dGlv
biBvZiB0aGUgUHJvZ3JhbSBieSBhbGwgdGhvc2Ugd2hvIHJlY2VpdmUKY29waWVzIGRpcmVjdGx5
IG9yIGluZGlyZWN0bHkgdGhyb3VnaCB5b3UsIHRoZW4gdGhlIG9ubHkgd2F5IHlvdSBjb3VsZCBz
YXRpc2Z5CmJvdGggaXQgYW5kIHRoaXMgTGljZW5zZSB3b3VsZCBiZSB0byByZWZyYWluIGVudGly
ZWx5IGZyb20gZGlzdHJpYnV0aW9uIG9mIHRoZQpQcm9ncmFtLgoKSWYgYW55IHBvcnRpb24gb2Yg
dGhpcyBzZWN0aW9uIGlzIGhlbGQgaW52YWxpZCBvciB1bmVuZm9yY2VhYmxlIHVuZGVyIGFueSBw
YXJ0aWN1bGFyCmNpcmN1bXN0YW5jZSwgdGhlIGJhbGFuY2Ugb2YgdGhlIHNlY3Rpb24gaXMgaW50
ZW5kZWQgdG8gYXBwbHkgYW5kIHRoZSBzZWN0aW9uIGFzCmEgd2hvbGUgaXMgaW50ZW5kZWQgdG8g
YXBwbHkgaW4gb3RoZXIgY2lyY3Vtc3RhbmNlcy4KCkl0IGlzIG5vdCB0aGUgcHVycG9zZSBvZiB0
aGlzIHNlY3Rpb24gdG8gaW5kdWNlIHlvdSB0byBpbmZyaW5nZSBhbnkgcGF0ZW50cyBvciBvdGhl
cgpwcm9wZXJ0eSByaWdodCBjbGFpbXMgb3IgdG8gY29udGVzdCB2YWxpZGl0eSBvZiBhbnkgc3Vj
aCBjbGFpbXM7IHRoaXMgc2VjdGlvbiBoYXMKdGhlIHNvbGUgcHVycG9zZSBvZiBwcm90ZWN0aW5n
IHRoZSBpbnRlZ3JpdHkgb2YgdGhlIGZyZWUgc29mdHdhcmUgZGlzdHJpYnV0aW9uCnN5c3RlbSwg
d2hpY2ggaXMgaW1wbGVtZW50ZWQgYnkgcHVibGljIGxpY2Vuc2UgcHJhY3RpY2VzLiBNYW55IHBl
b3BsZSBoYXZlCm1hZGUgZ2VuZXJvdXMgY29udHJpYnV0aW9ucyB0byB0aGUgd2lkZSByYW5nZSBv
ZiBzb2Z0d2FyZSBkaXN0cmlidXRlZCB0aHJvdWdoCnRoYXQgc3lzdGVtIGluIHJlbGlhbmNlIG9u
IGNvbnNpc3RlbnQgYXBwbGljYXRpb24gb2YgdGhhdCBzeXN0ZW07IGl0IGlzIHVwIHRvIHRoZQph
dXRob3IvZG9ub3IgdG8gZGVjaWRlIGlmIGhlIG9yIHNoZSBpcyB3aWxsaW5nIHRvIGRpc3RyaWJ1
dGUgc29mdHdhcmUgdGhyb3VnaCBhbnkKb3RoZXIgc3lzdGVtIGFuZCBhIGxpY2Vuc2VlIGNhbm5v
dCBpbXBvc2UgdGhhdCBjaG9pY2UuCgpUaGlzIHNlY3Rpb24gaXMgaW50ZW5kZWQgdG8gbWFrZSB0
aG9yb3VnaGx5IGNsZWFyIHdoYXQgaXMgYmVsaWV2ZWQgdG8gYmUgYQpjb25zZXF1ZW5jZSBvZiB0
aGUgcmVzdCBvZiB0aGlzIExpY2Vuc2UuCgo4LiBJZiB0aGUgZGlzdHJpYnV0aW9uIGFuZC9vciB1
c2Ugb2YgdGhlIFByb2dyYW0gaXMgcmVzdHJpY3RlZCBpbiBjZXJ0YWluIGNvdW50cmllcwplaXRo
ZXIgYnkgcGF0ZW50cyBvciBieSBjb3B5cmlnaHRlZCBpbnRlcmZhY2VzLCB0aGUgb3JpZ2luYWwg
Y29weXJpZ2h0IGhvbGRlciB3aG8KcGxhY2VzIHRoZSBQcm9ncmFtIHVuZGVyIHRoaXMgTGljZW5z
ZSBtYXkgYWRkIGFuIGV4cGxpY2l0IGdlb2dyYXBoaWNhbApkaXN0cmlidXRpb24gbGltaXRhdGlv
biBleGNsdWRpbmcgdGhvc2UgY291bnRyaWVzLCBzbyB0aGF0IGRpc3RyaWJ1dGlvbiBpcyBwZXJt
aXR0ZWQKb25seSBpbiBvciBhbW9uZyBjb3VudHJpZXMgbm90IHRodXMgZXhjbHVkZWQuIEluIHN1
Y2ggY2FzZSwgdGhpcyBMaWNlbnNlCmluY29ycG9yYXRlcyB0aGUgbGltaXRhdGlvbiBhcyBpZiB3
cml0dGVuIGluIHRoZSBib2R5IG9mIHRoaXMgTGljZW5zZS4KCjkuIFRoZSBGcmVlIFNvZnR3YXJl
IEZvdW5kYXRpb24gbWF5IHB1Ymxpc2ggcmV2aXNlZCBhbmQvb3IgbmV3IHZlcnNpb25zIG9mIHRo
ZQpHZW5lcmFsIFB1YmxpYyBMaWNlbnNlIGZyb20gdGltZSB0byB0aW1lLiBTdWNoIG5ldyB2ZXJz
aW9ucyB3aWxsIGJlIHNpbWlsYXIgaW4Kc3Bpcml0IHRvIHRoZSBwcmVzZW50IHZlcnNpb24sIGJ1
dCBtYXkgZGlmZmVyIGluIGRldGFpbCB0byBhZGRyZXNzIG5ldyBwcm9ibGVtcyBvcgpjb25jZXJu
cy4KCkVhY2ggdmVyc2lvbiBpcyBnaXZlbiBhIGRpc3Rpbmd1aXNoaW5nIHZlcnNpb24gbnVtYmVy
LiBJZiB0aGUgUHJvZ3JhbSBzcGVjaWZpZXMgYQp2ZXJzaW9uIG51bWJlciBvZiB0aGlzIExpY2Vu
c2Ugd2hpY2ggYXBwbGllcyB0byBpdCBhbmQgImFueSBsYXRlciB2ZXJzaW9uIiwgeW91CmhhdmUg
dGhlIG9wdGlvbiBvZiBmb2xsb3dpbmcgdGhlIHRlcm1zIGFuZCBjb25kaXRpb25zIGVpdGhlciBv
ZiB0aGF0IHZlcnNpb24gb3Igb2YKYW55IGxhdGVyIHZlcnNpb24gcHVibGlzaGVkIGJ5IHRoZSBG
cmVlIFNvZnR3YXJlIEZvdW5kYXRpb24uIElmIHRoZSBQcm9ncmFtIGRvZXMKbm90IHNwZWNpZnkg
YSB2ZXJzaW9uIG51bWJlciBvZiB0aGlzIExpY2Vuc2UsIHlvdSBtYXkgY2hvb3NlIGFueSB2ZXJz
aW9uIGV2ZXIKcHVibGlzaGVkIGJ5IHRoZSBGcmVlIFNvZnR3YXJlIEZvdW5kYXRpb24uCgoxMC4g
SWYgeW91IHdpc2ggdG8gaW5jb3Jwb3JhdGUgcGFydHMgb2YgdGhlIFByb2dyYW0gaW50byBvdGhl
ciBmcmVlIHByb2dyYW1zCndob3NlIGRpc3RyaWJ1dGlvbiBjb25kaXRpb25zIGFyZSBkaWZmZXJl
bnQsIHdyaXRlIHRvIHRoZSBhdXRob3IgdG8gYXNrIGZvcgpwZXJtaXNzaW9uLiBGb3Igc29mdHdh
cmUgd2hpY2ggaXMgY29weXJpZ2h0ZWQgYnkgdGhlIEZyZWUgU29mdHdhcmUgRm91bmRhdGlvbiwK
d3JpdGUgdG8gdGhlIEZyZWUgU29mdHdhcmUgRm91bmRhdGlvbjsgd2Ugc29tZXRpbWVzIG1ha2Ug
ZXhjZXB0aW9ucyBmb3IgdGhpcy4KT3VyIGRlY2lzaW9uIHdpbGwgYmUgZ3VpZGVkIGJ5IHRoZSB0
d28gZ29hbHMgb2YgcHJlc2VydmluZyB0aGUgZnJlZSBzdGF0dXMgb2YgYWxsCmRlcml2YXRpdmVz
IG9mIG91ciBmcmVlIHNvZnR3YXJlIGFuZCBvZiBwcm9tb3RpbmcgdGhlIHNoYXJpbmcgYW5kIHJl
dXNlIG9mCnNvZnR3YXJlIGdlbmVyYWxseS4KCk5PIFdBUlJBTlRZCgoxMS4gQkVDQVVTRSBUSEUg
UFJPR1JBTSBJUyBMSUNFTlNFRCBGUkVFIE9GIENIQVJHRSwgVEhFUkUgSVMKTk8gV0FSUkFOVFkg
Rk9SIFRIRSBQUk9HUkFNLCBUTyBUSEUgRVhURU5UIFBFUk1JVFRFRCBCWQpBUFBMSUNBQkxFIExB
Vy4gRVhDRVBUIFdIRU4gT1RIRVJXSVNFIFNUQVRFRCBJTiBXUklUSU5HIFRIRQpDT1BZUklHSFQg
SE9MREVSUyBBTkQvT1IgT1RIRVIgUEFSVElFUyBQUk9WSURFIFRIRSBQUk9HUkFNCiJBUyBJUyIg
V0lUSE9VVCBXQVJSQU5UWSBPRiBBTlkgS0lORCwgRUlUSEVSIEVYUFJFU1NFRCBPUgpJTVBMSUVE
LCBJTkNMVURJTkcsIEJVVCBOT1QgTElNSVRFRCBUTywgVEhFIElNUExJRUQgV0FSUkFOVElFUyBP
RgpNRVJDSEFOVEFCSUxJVFkgQU5EIEZJVE5FU1MgRk9SIEEgUEFSVElDVUxBUiBQVVJQT1NFLiBU
SEUKRU5USVJFIFJJU0sgQVMgVE8gVEhFIFFVQUxJVFkgQU5EIFBFUkZPUk1BTkNFIE9GIFRIRQpQ
Uk9HUkFNIElTIFdJVEggWU9VLiBTSE9VTEQgVEhFIFBST0dSQU0gUFJPVkUgREVGRUNUSVZFLApZ
T1UgQVNTVU1FIFRIRSBDT1NUIE9GIEFMTCBORUNFU1NBUlkgU0VSVklDSU5HLCBSRVBBSVIgT1IK
Q09SUkVDVElPTi4KCjEyLiBJTiBOTyBFVkVOVCBVTkxFU1MgUkVRVUlSRUQgQlkgQVBQTElDQUJM
RSBMQVcgT1IgQUdSRUVEClRPIElOIFdSSVRJTkcgV0lMTCBBTlkgQ09QWVJJR0hUIEhPTERFUiwg
T1IgQU5ZIE9USEVSIFBBUlRZCldITyBNQVkgTU9ESUZZIEFORC9PUiBSRURJU1RSSUJVVEUgVEhF
IFBST0dSQU0gQVMKUEVSTUlUVEVEIEFCT1ZFLCBCRSBMSUFCTEUgVE8gWU9VIEZPUiBEQU1BR0VT
LCBJTkNMVURJTkcgQU5ZCkdFTkVSQUwsIFNQRUNJQUwsIElOQ0lERU5UQUwgT1IgQ09OU0VRVUVO
VElBTCBEQU1BR0VTCkFSSVNJTkcgT1VUIE9GIFRIRSBVU0UgT1IgSU5BQklMSVRZIFRPIFVTRSBU
SEUgUFJPR1JBTQooSU5DTFVESU5HIEJVVCBOT1QgTElNSVRFRCBUTyBMT1NTIE9GIERBVEEgT1Ig
REFUQSBCRUlORwpSRU5ERVJFRCBJTkFDQ1VSQVRFIE9SIExPU1NFUyBTVVNUQUlORUQgQlkgWU9V
IE9SIFRISVJEClBBUlRJRVMgT1IgQSBGQUlMVVJFIE9GIFRIRSBQUk9HUkFNIFRPIE9QRVJBVEUg
V0lUSCBBTlkKT1RIRVIgUFJPR1JBTVMpLCBFVkVOIElGIFNVQ0ggSE9MREVSIE9SIE9USEVSIFBB
UlRZIEhBUwpCRUVOIEFEVklTRUQgT0YgVEhFIFBPU1NJQklMSVRZIE9GIFNVQ0ggREFNQUdFUy4K
CkVORCBPRiBURVJNUyBBTkQgQ09ORElUSU9OUwoKCi0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KClRoZSBB
cnRpc3RpYyBMaWNlbnNlCgpQcmVhbWJsZQoKVGhlIGludGVudCBvZiB0aGlzIGRvY3VtZW50IGlz
IHRvIHN0YXRlIHRoZSBjb25kaXRpb25zIHVuZGVyIHdoaWNoIGEgUGFja2FnZQptYXkgYmUgY29w
aWVkLCBzdWNoIHRoYXQgdGhlIENvcHlyaWdodCBIb2xkZXIgbWFpbnRhaW5zIHNvbWUgc2VtYmxh
bmNlIG9mCmFydGlzdGljIGNvbnRyb2wgb3ZlciB0aGUgZGV2ZWxvcG1lbnQgb2YgdGhlIHBhY2th
Z2UsIHdoaWxlIGdpdmluZyB0aGUgdXNlcnMgb2YgdGhlCnBhY2thZ2UgdGhlIHJpZ2h0IHRvIHVz
ZSBhbmQgZGlzdHJpYnV0ZSB0aGUgUGFja2FnZSBpbiBhIG1vcmUtb3ItbGVzcyBjdXN0b21hcnkK
ZmFzaGlvbiwgcGx1cyB0aGUgcmlnaHQgdG8gbWFrZSByZWFzb25hYmxlIG1vZGlmaWNhdGlvbnMu
CgpEZWZpbml0aW9uczoKCi0gICAgIlBhY2thZ2UiIHJlZmVycyB0byB0aGUgY29sbGVjdGlvbiBv
ZiBmaWxlcyBkaXN0cmlidXRlZCBieSB0aGUgQ29weXJpZ2h0CiAgICAgSG9sZGVyLCBhbmQgZGVy
aXZhdGl2ZXMgb2YgdGhhdCBjb2xsZWN0aW9uIG9mIGZpbGVzIGNyZWF0ZWQgdGhyb3VnaCB0ZXh0
dWFsCiAgICAgbW9kaWZpY2F0aW9uLiAKLSAgICAiU3RhbmRhcmQgVmVyc2lvbiIgcmVmZXJzIHRv
IHN1Y2ggYSBQYWNrYWdlIGlmIGl0IGhhcyBub3QgYmVlbiBtb2RpZmllZCwKICAgICBvciBoYXMg
YmVlbiBtb2RpZmllZCBpbiBhY2NvcmRhbmNlIHdpdGggdGhlIHdpc2hlcyBvZiB0aGUgQ29weXJp
Z2h0CiAgICAgSG9sZGVyLiAKLSAgICAiQ29weXJpZ2h0IEhvbGRlciIgaXMgd2hvZXZlciBpcyBu
YW1lZCBpbiB0aGUgY29weXJpZ2h0IG9yIGNvcHlyaWdodHMgZm9yCiAgICAgdGhlIHBhY2thZ2Uu
IAotICAgICJZb3UiIGlzIHlvdSwgaWYgeW91J3JlIHRoaW5raW5nIGFib3V0IGNvcHlpbmcgb3Ig
ZGlzdHJpYnV0aW5nIHRoaXMgUGFja2FnZS4KLSAgICAiUmVhc29uYWJsZSBjb3B5aW5nIGZlZSIg
aXMgd2hhdGV2ZXIgeW91IGNhbiBqdXN0aWZ5IG9uIHRoZSBiYXNpcyBvZgogICAgIG1lZGlhIGNv
c3QsIGR1cGxpY2F0aW9uIGNoYXJnZXMsIHRpbWUgb2YgcGVvcGxlIGludm9sdmVkLCBhbmQgc28g
b24uIChZb3UKICAgICB3aWxsIG5vdCBiZSByZXF1aXJlZCB0byBqdXN0aWZ5IGl0IHRvIHRoZSBD
b3B5cmlnaHQgSG9sZGVyLCBidXQgb25seSB0byB0aGUKICAgICBjb21wdXRpbmcgY29tbXVuaXR5
IGF0IGxhcmdlIGFzIGEgbWFya2V0IHRoYXQgbXVzdCBiZWFyIHRoZSBmZWUuKSAKLSAgICAiRnJl
ZWx5IEF2YWlsYWJsZSIgbWVhbnMgdGhhdCBubyBmZWUgaXMgY2hhcmdlZCBmb3IgdGhlIGl0ZW0g
aXRzZWxmLCB0aG91Z2gKICAgICB0aGVyZSBtYXkgYmUgZmVlcyBpbnZvbHZlZCBpbiBoYW5kbGlu
ZyB0aGUgaXRlbS4gSXQgYWxzbyBtZWFucyB0aGF0CiAgICAgcmVjaXBpZW50cyBvZiB0aGUgaXRl
bSBtYXkgcmVkaXN0cmlidXRlIGl0IHVuZGVyIHRoZSBzYW1lIGNvbmRpdGlvbnMgdGhleQogICAg
IHJlY2VpdmVkIGl0LiAKCjEuIFlvdSBtYXkgbWFrZSBhbmQgZ2l2ZSBhd2F5IHZlcmJhdGltIGNv
cGllcyBvZiB0aGUgc291cmNlIGZvcm0gb2YgdGhlClN0YW5kYXJkIFZlcnNpb24gb2YgdGhpcyBQ
YWNrYWdlIHdpdGhvdXQgcmVzdHJpY3Rpb24sIHByb3ZpZGVkIHRoYXQgeW91IGR1cGxpY2F0ZQph
bGwgb2YgdGhlIG9yaWdpbmFsIGNvcHlyaWdodCBub3RpY2VzIGFuZCBhc3NvY2lhdGVkIGRpc2Ns
YWltZXJzLgoKMi4gWW91IG1heSBhcHBseSBidWcgZml4ZXMsIHBvcnRhYmlsaXR5IGZpeGVzIGFu
ZCBvdGhlciBtb2RpZmljYXRpb25zIGRlcml2ZWQgZnJvbQp0aGUgUHVibGljIERvbWFpbiBvciBm
cm9tIHRoZSBDb3B5cmlnaHQgSG9sZGVyLiBBIFBhY2thZ2UgbW9kaWZpZWQgaW4gc3VjaCBhCndh
eSBzaGFsbCBzdGlsbCBiZSBjb25zaWRlcmVkIHRoZSBTdGFuZGFyZCBWZXJzaW9uLgoKMy4gWW91
IG1heSBvdGhlcndpc2UgbW9kaWZ5IHlvdXIgY29weSBvZiB0aGlzIFBhY2thZ2UgaW4gYW55IHdh
eSwgcHJvdmlkZWQKdGhhdCB5b3UgaW5zZXJ0IGEgcHJvbWluZW50IG5vdGljZSBpbiBlYWNoIGNo
YW5nZWQgZmlsZSBzdGF0aW5nIGhvdyBhbmQgd2hlbgp5b3UgY2hhbmdlZCB0aGF0IGZpbGUsIGFu
ZCBwcm92aWRlZCB0aGF0IHlvdSBkbyBhdCBsZWFzdCBPTkUgb2YgdGhlIGZvbGxvd2luZzoKCiAg
ICAgYSkgcGxhY2UgeW91ciBtb2RpZmljYXRpb25zIGluIHRoZSBQdWJsaWMgRG9tYWluIG9yIG90
aGVyd2lzZQogICAgIG1ha2UgdGhlbSBGcmVlbHkgQXZhaWxhYmxlLCBzdWNoIGFzIGJ5IHBvc3Rp
bmcgc2FpZCBtb2RpZmljYXRpb25zCiAgICAgdG8gVXNlbmV0IG9yIGFuIGVxdWl2YWxlbnQgbWVk
aXVtLCBvciBwbGFjaW5nIHRoZSBtb2RpZmljYXRpb25zIG9uCiAgICAgYSBtYWpvciBhcmNoaXZl
IHNpdGUgc3VjaCBhcyBmdHAudXUubmV0LCBvciBieSBhbGxvd2luZyB0aGUKICAgICBDb3B5cmln
aHQgSG9sZGVyIHRvIGluY2x1ZGUgeW91ciBtb2RpZmljYXRpb25zIGluIHRoZSBTdGFuZGFyZAog
ICAgIFZlcnNpb24gb2YgdGhlIFBhY2thZ2UuCgogICAgIGIpIHVzZSB0aGUgbW9kaWZpZWQgUGFj
a2FnZSBvbmx5IHdpdGhpbiB5b3VyIGNvcnBvcmF0aW9uIG9yCiAgICAgb3JnYW5pemF0aW9uLgoK
ICAgICBjKSByZW5hbWUgYW55IG5vbi1zdGFuZGFyZCBleGVjdXRhYmxlcyBzbyB0aGUgbmFtZXMg
ZG8gbm90CiAgICAgY29uZmxpY3Qgd2l0aCBzdGFuZGFyZCBleGVjdXRhYmxlcywgd2hpY2ggbXVz
dCBhbHNvIGJlIHByb3ZpZGVkLAogICAgIGFuZCBwcm92aWRlIGEgc2VwYXJhdGUgbWFudWFsIHBh
Z2UgZm9yIGVhY2ggbm9uLXN0YW5kYXJkCiAgICAgZXhlY3V0YWJsZSB0aGF0IGNsZWFybHkgZG9j
dW1lbnRzIGhvdyBpdCBkaWZmZXJzIGZyb20gdGhlIFN0YW5kYXJkCiAgICAgVmVyc2lvbi4KCiAg
ICAgZCkgbWFrZSBvdGhlciBkaXN0cmlidXRpb24gYXJyYW5nZW1lbnRzIHdpdGggdGhlIENvcHly
aWdodCBIb2xkZXIuCgo0LiBZb3UgbWF5IGRpc3RyaWJ1dGUgdGhlIHByb2dyYW1zIG9mIHRoaXMg
UGFja2FnZSBpbiBvYmplY3QgY29kZSBvciBleGVjdXRhYmxlCmZvcm0sIHByb3ZpZGVkIHRoYXQg
eW91IGRvIGF0IGxlYXN0IE9ORSBvZiB0aGUgZm9sbG93aW5nOgoKICAgICBhKSBkaXN0cmlidXRl
IGEgU3RhbmRhcmQgVmVyc2lvbiBvZiB0aGUgZXhlY3V0YWJsZXMgYW5kIGxpYnJhcnkKICAgICBm
aWxlcywgdG9nZXRoZXIgd2l0aCBpbnN0cnVjdGlvbnMgKGluIHRoZSBtYW51YWwgcGFnZSBvciBl
cXVpdmFsZW50KQogICAgIG9uIHdoZXJlIHRvIGdldCB0aGUgU3RhbmRhcmQgVmVyc2lvbi4KCiAg
ICAgYikgYWNjb21wYW55IHRoZSBkaXN0cmlidXRpb24gd2l0aCB0aGUgbWFjaGluZS1yZWFkYWJs
ZSBzb3VyY2Ugb2YKICAgICB0aGUgUGFja2FnZSB3aXRoIHlvdXIgbW9kaWZpY2F0aW9ucy4KCiAg
ICAgYykgYWNjb21wYW55IGFueSBub24tc3RhbmRhcmQgZXhlY3V0YWJsZXMgd2l0aCB0aGVpcgog
ICAgIGNvcnJlc3BvbmRpbmcgU3RhbmRhcmQgVmVyc2lvbiBleGVjdXRhYmxlcywgZ2l2aW5nIHRo
ZQogICAgIG5vbi1zdGFuZGFyZCBleGVjdXRhYmxlcyBub24tc3RhbmRhcmQgbmFtZXMsIGFuZCBj
bGVhcmx5CiAgICAgZG9jdW1lbnRpbmcgdGhlIGRpZmZlcmVuY2VzIGluIG1hbnVhbCBwYWdlcyAo
b3IgZXF1aXZhbGVudCksCiAgICAgdG9nZXRoZXIgd2l0aCBpbnN0cnVjdGlvbnMgb24gd2hlcmUg
dG8gZ2V0IHRoZSBTdGFuZGFyZCBWZXJzaW9uLgoKICAgICBkKSBtYWtlIG90aGVyIGRpc3RyaWJ1
dGlvbiBhcnJhbmdlbWVudHMgd2l0aCB0aGUgQ29weXJpZ2h0IEhvbGRlci4KCjUuIFlvdSBtYXkg
Y2hhcmdlIGEgcmVhc29uYWJsZSBjb3B5aW5nIGZlZSBmb3IgYW55IGRpc3RyaWJ1dGlvbiBvZiB0
aGlzIFBhY2thZ2UuCllvdSBtYXkgY2hhcmdlIGFueSBmZWUgeW91IGNob29zZSBmb3Igc3VwcG9y
dCBvZiB0aGlzIFBhY2thZ2UuIFlvdSBtYXkgbm90CmNoYXJnZSBhIGZlZSBmb3IgdGhpcyBQYWNr
YWdlIGl0c2VsZi4gSG93ZXZlciwgeW91IG1heSBkaXN0cmlidXRlIHRoaXMgUGFja2FnZSBpbgph
Z2dyZWdhdGUgd2l0aCBvdGhlciAocG9zc2libHkgY29tbWVyY2lhbCkgcHJvZ3JhbXMgYXMgcGFy
dCBvZiBhIGxhcmdlcgoocG9zc2libHkgY29tbWVyY2lhbCkgc29mdHdhcmUgZGlzdHJpYnV0aW9u
IHByb3ZpZGVkIHRoYXQgeW91IGRvIG5vdCBhZHZlcnRpc2UKdGhpcyBQYWNrYWdlIGFzIGEgcHJv
ZHVjdCBvZiB5b3VyIG93bi4KCjYuIFRoZSBzY3JpcHRzIGFuZCBsaWJyYXJ5IGZpbGVzIHN1cHBs
aWVkIGFzIGlucHV0IHRvIG9yIHByb2R1Y2VkIGFzIG91dHB1dCBmcm9tCnRoZSBwcm9ncmFtcyBv
ZiB0aGlzIFBhY2thZ2UgZG8gbm90IGF1dG9tYXRpY2FsbHkgZmFsbCB1bmRlciB0aGUgY29weXJp
Z2h0IG9mIHRoaXMKUGFja2FnZSwgYnV0IGJlbG9uZyB0byB3aG9tZXZlciBnZW5lcmF0ZWQgdGhl
bSwgYW5kIG1heSBiZSBzb2xkCmNvbW1lcmNpYWxseSwgYW5kIG1heSBiZSBhZ2dyZWdhdGVkIHdp
dGggdGhpcyBQYWNrYWdlLgoKNy4gQyBvciBwZXJsIHN1YnJvdXRpbmVzIHN1cHBsaWVkIGJ5IHlv
dSBhbmQgbGlua2VkIGludG8gdGhpcyBQYWNrYWdlIHNoYWxsIG5vdApiZSBjb25zaWRlcmVkIHBh
cnQgb2YgdGhpcyBQYWNrYWdlLgoKOC4gVGhlIG5hbWUgb2YgdGhlIENvcHlyaWdodCBIb2xkZXIg
bWF5IG5vdCBiZSB1c2VkIHRvIGVuZG9yc2Ugb3IgcHJvbW90ZQpwcm9kdWN0cyBkZXJpdmVkIGZy
b20gdGhpcyBzb2Z0d2FyZSB3aXRob3V0IHNwZWNpZmljIHByaW9yIHdyaXR0ZW4gcGVybWlzc2lv
bi4KCjkuIFRISVMgUEFDS0FHRSBJUyBQUk9WSURFRCAiQVMgSVMiIEFORCBXSVRIT1VUIEFOWSBF
WFBSRVNTIE9SCklNUExJRUQgV0FSUkFOVElFUywgSU5DTFVESU5HLCBXSVRIT1VUIExJTUlUQVRJ
T04sIFRIRSBJTVBMSUVECldBUlJBTlRJRVMgT0YgTUVSQ0hBTlRJQklMSVRZIEFORCBGSVRORVNT
IEZPUiBBIFBBUlRJQ1VMQVIKUFVSUE9TRS4KClRoZSBFbmQKCg==
-----END FILE-----

-----BEGIN FILE-----
Name: MANIFEST
File: MANIFEST
Mode: 644

# Generated by %AUTHOR% %GMT%
# %DOLLAR%Id%DOLLAR%

# Common files
Changes                 Changes list
INSTALL                 Install file
LICENSE                 License file
Makefile.PL             Makefile builder
MANIFEST                This file
README                  !!! READ ME FIRST !!!
TODO                    TO DO list

# Libraries
lib/MPM/%PROJECT_NAME%.pm

# Tests
t/01-use.t              Test script

# Sources
src/META.yml            META file after creating
src/%PROJECT_NAMEL%_apache2.conf

-----END FILE-----

-----BEGIN FILE-----
Name: Makefile.PL
File: Makefile.PL
Mode: 711

#!/usr/bin/perl -w
use strict; # %DOLLAR%Id%DOLLAR%

use ExtUtils::MakeMaker;

use constant {
        PROJECT_NAME    => '%PROJECT_NAME%',
        AUTHOR          => '%AUTHOR%',
        SERVER_ADMIN    => '%SERVER_ADMIN%',
    };

# Build requirements
my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
    };

# Requirements
my $prereq_pm = {
        'MPMinus'       => 1.21,
    };

WriteMakefile(
    'NAME'                  => sprintf('MPM::%s', PROJECT_NAME),
    'MIN_PERL_VERSION'      => 5.016001,
    'VERSION_FROM'          => sprintf('lib/MPM/%s.pm', PROJECT_NAME),
    'ABSTRACT_FROM'         => sprintf('lib/MPM/%s.pm', PROJECT_NAME),
    'BUILD_REQUIRES'        => $build_requires,
    'PREREQ_PM'             => $prereq_pm,
    'AUTHOR'                => sprintf('%s <%s>', AUTHOR, SERVER_ADMIN),
    'LICENSE'               => 'perl',
    'META_MERGE' => { "meta-spec" => { version => 2 },
        resources => {
            mpminus         => 'https://metacpan.org/release/MPMinus',
            license         => 'https://dev.perl.org/licenses/',
        },
    },
);

1;

%ENDSIGN%
-----END FILE-----

-----BEGIN FILE-----
Name: README
File: README
Mode: 644

#
# This file contains a description of Your project, written in a free style.
# But we recommend that You use the pod2readme utility.
#
#   pod2readme lib/MPM/%PROJECT_NAME%.pm
#
# Please override the contents of this file!
#

-----END FILE-----

-----BEGIN FILE-----
Name: TODO
File: TODO
Mode: 644

# %TODO% %GMT%
# %DOLLAR%Id%DOLLAR%

# GENERAL

    * none

# BUGS

    * none

# REFACTORING

    * none

# DOCUMENTATION

    * none

# DIAGNOSTICS

    * none

# SUPPORT

    * none

-----END FILE-----

-----BEGIN FILE-----
Name: META.yml
File: src/META.yml
Mode: 644

---
PROJECT_NAME:         '%PROJECT_NAME%'
PROJECT_NAMEL:        '%PROJECT_NAMEL%'
PROJECT_VERSION:      '%PROJECT_VERSION%'
PROJECT_TYPE:         '%PROJECT_TYPE%'
SERVER_NAME:          '%SERVER_NAME%'
DOCUMENT_ROOT:        '%DOCUMENT_ROOT%'
MODPERL_ROOT:         '%MODPERL_ROOT%'
SERVER_VERSION:       '%SERVER_VERSION%'
APACHE_VERSION:       '%APACHE_VERSION%'
APACHE_SIGN:          '%APACHE_SIGN%'
HTTPD_ROOT:           '%HTTPD_ROOT%'
SERVER_CONFIG_FILE:   '%SERVER_CONFIG_FILE%'
AUTHOR:               '%AUTHOR%'
SERVER_ADMIN:         '%SERVER_ADMIN%'
GMT:                  '%GMT%'
-----END FILE-----

-----BEGIN FILE-----
Name: %PROJECT_NAMEL%_apache2.conf
File: src/%PROJECT_NAMEL%_apache2.conf
Mode: 644

# Apache2 config section
<IfModule mod_perl.c>
    PerlModule MPM::%PROJECT_NAME%
    PerlOptions +GlobalRequest
    <Location /%PROJECT_NAMEL%>
        PerlInitHandler MPM::%PROJECT_NAME%
        PerlSetVar Location %PROJECT_NAMEL%
        PerlSetVar Debug on
        PerlSetVar TestValue Blah-Blah-Blah
    </Location>
</IfModule>
-----END FILE-----

-----BEGIN FILE-----
Name: %PROJECT_NAME%.pm
File: lib/MPM/%PROJECT_NAME%.pm
Mode: 644

package MPM::%PROJECT_NAME%; # %DOLLAR%Id%DOLLAR%
use strict;
use utf8;

%PODSIG%encoding utf8

%PODSIG%head1 NAME

MPM::%PROJECT_NAME% - REST controller

%PODSIG%head1 VERSION

Version %PROJECT_VERSION%

%PODSIG%head1 SYNOPSIS

  # Apache2 config section
  <IfModule mod_perl.c>
    PerlOptions +GlobalRequest
    PerlModule MPM::%PROJECT_NAME%
    <Location /%PROJECT_NAMEL%>
      PerlInitHandler MPM::%PROJECT_NAME%
      PerlSetVar Location %PROJECT_NAMEL%
      PerlSetVar Debug on
      PerlSetVar TestValue Blah-Blah-Blah
    </Location>
  </IfModule>

%PODSIG%head1 DESCRIPTION

REST controller

%PODSIG%cut

use vars qw/ $VERSION /;
$VERSION = '%PROJECT_VERSION%';

use base qw/MPMinus::REST/;

use Apache2::Util;
use Apache2::Const -compile => qw/ :common :http /;

use Encode;

use MPMinus::Util qw/ getHiTime /;

%PODSIG%head1 METHODS

Base methods

%PODSIG%head2 handler

See L<MPMinus::REST/handler>

%PODSIG%head2 hInit

See L<MPMinus::REST/hInit>

%PODSIG%cut

sub handler : method {
    my $class = (@_ >= 2) ? shift : __PACKAGE__;
    my $r = shift;
    #
    # ... preinit statements ...
    #
    return $class->init($r);
}

sub hInit {
    my $self = shift;
    my $r = shift;

    # Dir config variables
    $self->set_dvar(testvalue => $r->dir_config("testvalue") // "");

    # Session variables
    $self->set_svar(init_label => __PACKAGE__);

    return $self->SUPER::hInit($r);
}

%PODSIG%head1 RAMST METHODS

RAMST methods

%PODSIG%head2 GET /%PROJECT_NAMEL%

    curl -v --raw -H "Accept: application/json" http://localhost/%PROJECT_NAMEL%?bar=123

    > GET /%PROJECT_NAMEL%?bar=123 HTTP/1.1
    > Host: localhost
    > User-Agent: curl/7.50.1
    > Accept: application/json
    >
    < HTTP/1.1 200 OK
    < Date: Thu, 25 Apr 2019 12:30:55 GMT
    < Server: Apache/2.4.18 (Ubuntu)
    < Content-Length: 528
    < Content-Type: application/json
    <
    {
       "key" : "GET#/#default",
       "uri" : "/%PROJECT_NAMEL%",
       "dvars" : {
          "debug" : "on",
          "testvalue" : "Blah-Blah-Blah",
          "location" : "%PROJECT_NAMEL%"
       },
       "remote_addr" : "127.0.0.1",
       "name" : "getIndex",
       "usr" : {
          "bar" : "123"
       },
       "stamp" : "[26264] MPM::%PROJECT_NAME% at Thu Apr 25 15:30:55 2019",
       "code" : 200,
       "error" : "",
       "foo_attr" : "My foo attribute value",
       "servers" : [
          "MPM-Foo#%PROJECT_NAMEL%"
       ],
       "path" : "/",
       "server_status" : 1,
       "debug_time" : "0.003",
       "location" : "%PROJECT_NAMEL%"
    }

Examples:

    curl -v --raw http://localhost/%PROJECT_NAMEL%
    curl -v --raw -H "Accept: application/json" http://localhost/%PROJECT_NAMEL%
    curl -v --raw -H "Accept: application/xml" http://localhost/%PROJECT_NAMEL%
    curl -v --raw -H "Accept: application/x-yaml" http://localhost/%PROJECT_NAMEL%

%PODSIG%cut

__PACKAGE__->register_handler( # GET /
    handler => "getIndex",
    method  => "GET",
    path    => "/",
    query   => undef,
    attrs   => {
            foo             => 'My foo attribute value',
            #debug           => 'on',
            #content_type    => 'application/json',
            #deserialize     => 1,
            serialize       => 1,
        },
    description => "Index",
    code    => sub {
    my $self = shift;
    my $name = shift;
    my $r = shift;
    my $q = $self->get("q");
    my $usr = $self->get("usr");
    #my $req_data = $self->get("req_data");
    #my $res_data = $self->get("res_data");

    # Output
    my $uri = $r->uri || ""; $uri =~ s/\/+$//;
    $self->set( res_data => {
        foo_attr        => $self->get_attr("foo"),
        name            => $name,
        server_status   => $self->status,
        code            => $self->code,
        error           => $self->error,
        key             => $self->get_svar("key"),
        path            => $self->get_svar("path"),
        remote_addr     => $self->get_svar("remote_addr"),
        location        => $self->{location},
        stamp           => $self->{stamp},
        dvars           => $self->{dvars},
        uri             => $uri,
        debug_time      => sprintf("%.3f", (getHiTime() - $self->get_svar('hitime'))),
        usr             => $usr,
        servers         => [$self->registered_servers],
    });

    return 1; # Or 0 only!!
});

%PODSIG%head1 HISTORY

See C<Changes> file

%PODSIG%head1 DEPENDENCIES

C<mod_perl2>, L<MPMinus>, L<MPMinus::REST>

%PODSIG%head1 TO DO

See C<TODO> file

%PODSIG%head1 BUGS

* none noted

%PODSIG%head1 SEE ALSO

L<MPMinus>, L<MPMinus::REST>, Examples on L<MPMinus>

%PODSIG%head1 AUTHOR

%AUTHOR% E<lt>%SERVER_ADMIN%E<gt>

%PODSIG%head1 COPYRIGHT

Copyright (C) %YEAR% %AUTHOR%. All Rights Reserved

%PODSIG%head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

%PODSIG%cut

1;

%ENDSIGN%
-----END FILE-----

-----BEGIN FILE-----
Name: 01-use.t
File: t/01-use.t
Mode: 644

#!/usr/bin/perl -w
#########################################################################
#
# %AUTHOR%, <%SERVER_ADMIN%>
#
# Copyright (C) %YEAR% %AUTHOR%. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# %DOLLAR%Id%DOLLAR%
#
#########################################################################
use Test::More tests => 2;
BEGIN { use_ok('MPM::%PROJECT_NAME%'); };
ok(MPM::%PROJECT_NAME%->VERSION,'Version checking');
1;

-----END FILE-----
