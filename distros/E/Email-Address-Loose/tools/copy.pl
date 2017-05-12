use strict;
use warnings;
use autodie qw/:all/;
use LWP::Simple;
use FindBin;

=for note

WHY NEED THIS?

Because I want to keep Email::Address::Loose's behavior
same as Email::Address except local-part.

And I want to make local-part is the same behavior
with Email::Valid::Loose.

=cut

copy_email_valid_loose('0.05');
copy_email_address('1.892');
exit;

sub copy_email_valid_loose {
    my $version = shift;
    
    warn "get Email::Valid::Loose $version...";
    my $module = get("http://search.cpan.org/src/MIYAGAWA/Email-Valid-Loose-$version/lib/Email/Valid/Loose.pm")
        or die $!;

    my $header = <<"...";
package Email::Address::Loose::EmailValidLoose;

# Note:
# The following code were copied from Email::Valid::Loose $version.
# http://search.cpan.org/perldoc?Email::Valid::Loose
# To make same behavior with Email::Valid::Loose about local-part.

...
    
    $module =~ s/^package Email::Valid::Loose;/$header\n\n/m;
    $module =~ s/^=.+?^=cut\n//msg; # strip pod
    $module =~ s/^(use Email::Valid.+)/# $1 # Note: don't need/m;
    $module =~ s/^(use base.+)/# $1 # Note: don't need/m;
    $module =~ s/^sub rfc822 {.*//ms;
    $module .= "sub peek_local_part { qr/\$local_part/ } # Note: added by Email::Address::Loose\n1;\n";
     
    warn "make EmailValidLoose.pm...";
    open(my $fh, '>', "$FindBin::Bin/../lib/Email/Address/Loose/EmailValidLoose.pm");
    print $fh $module;
    close $fh;
}

sub copy_email_address {
    my $version = shift;
    
    warn "get Email::Address $version...";
    system("rm -rf $FindBin::Bin/../email-address");
    system('git clone -q git://github.com/rjbs/email-address.git');
    system("cd email-address; git checkout -q tags/$version");
    
    my $module = do {
        open my $fh, '<', "$FindBin::Bin/../email-address/lib/Email/Address.pm";
        local $/; <$fh>
    };

    my $header = <<"...";
package Email::Address::Loose::EmailAddress;

## no critic
use base 'Email::Address'; # for isa("Email::Address");
use Email::Address::Loose::EmailValidLoose;

# Note:
# The following code were copied from Email::Address $version.
# http://search.cpan.org/perldoc?Email::Address
# To make same behavior with Email::Address escept local-part.

...
    
    $module =~ s/^package Email::Address;/$header\n\n/m;
    $module =~ s/^=.+?^=cut\n//msg; # strip pod
    $module =~ s/^(sub parse {\n\s+my \(\$class, \$line\) = \@_;)/$1\n    \$class = 'Email::Address::Loose' if \$class eq 'Email::Address'; # Note: added by Email::Address::Loose\n/m;
    $module =~ s/^(my \$local_part\s+=.*)/$1\n\$local_part = Email::Address::Loose::EmailValidLoose->peek_local_part; # Note: added by Email::Address::Loose\n/m;
    $module =~ s/^__END__.*//ms;
    
    warn "make EmailAddress.pm...";
    open(my $fh, '>', "$FindBin::Bin/../lib/Email/Address/Loose/EmailAddress.pm");
    print $fh $module;
    close $fh;
    
    warn "make t/regression-email-address/*.t...";
    system("rm -rf $FindBin::Bin/../t/regression-email-address/*.t");
    system("cp -r $FindBin::Bin/../email-address/t/*.t $FindBin::Bin/../t/regression-email-address/");
    system("rm $FindBin::Bin/../t/regression-email-address/pod*");
    
    for my $file (glob "$FindBin::Bin/../t/regression-email-address/*.t") {
        open my $fh, '+<', $file or die $!;
        my $text = do { local $/; <$fh> };
        seek $fh, 0, 0;
        print $fh "use Email::Address::Loose -override; # added by Email::Address::Loose\n\n";
        print $fh $text;
    }
    
    system("rm -rf $FindBin::Bin/../email-address");
}
