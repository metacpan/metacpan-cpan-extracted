package Mail::POP3::Security::User;

use strict;

sub check_password_pam {
    my ($class, $config, $user_name, $fqdn, $supplied_password) = @_;
    require Authen::PAM;
    my $pamh = Authen::PAM->new(
        $config->{mpopd_pam_service},
        $user_name,
        sub {
            my @res;
            while ( @_ ) {
                my $code = shift;
                my $msg = shift;
                my $ans = "";
                $ans = $user_name if $code == PAM_PROMPT_ECHO_ON();
                $ans = $supplied_password if $code == PAM_PROMPT_ECHO_OFF();
                push @res, (PAM_SUCCESS(),$ans);
            }
            push @res, PAM_SUCCESS();
            return @res;
        },
    ) || die "Error during PAM init";
    return $pamh->pam_authenticate == 0;
}

sub check_password_system_md5_nopam {
    my ($class, $config, $user_name, $fqdn, $supplied_password) = @_;
    my $crypted = (getpwnam $user_name)[1];
    my ($salt) = $crypted =~ /^\$1\$(.{8})\$/;
    return unix_md5_crypt($supplied_password, $salt) eq $crypted;
}

sub check_user_system {
    my ($class, $config, $user_name, $fqdn) = @_;
    () = getpwnam $user_name;
}

sub check_password_system {
    my ($class, $config, $user_name, $fqdn, $supplied_password) = @_;
    my $crypted = (getpwnam $user_name)[1];
    if (defined($config->{shadow})) {
        ($crypted) = $class->get_user_from_file($user_name, $config->{shadow});
    }
    crypt($supplied_password, $crypted) eq $crypted;
}

sub get_userid_system {
    my ($class, $user_name) = @_;
    scalar getpwnam $user_name;
}

# Read a non-system password file for domain-name hashed
# mail boxes. Format: username:password:uid
#              e.g. markjt:$1$d56geIhf$agr7nng92bgf32:100
# The uid should correspond to the system 'mail' user or
# a special 'mpopd' system user in /etc/passwd
sub check_user_vdomain {
    my ($class, $config, $user_name, $fqdn) = @_;
    my ($initial) = $fqdn =~ /^(.)/;
    my $vdomain_dir = "$config->{host_mail_path}/$initial/$fqdn";
    () = $class->get_user_from_file(
        $user_name,
        "$vdomain_dir/$config->{userlist}",
    );
}

sub check_password_vdomain {
    my ($class, $config, $user_name, $fqdn, $supplied_password) = @_;
    my ($initial) = $fqdn =~ /^(.)/;
    my $vdomain_dir = "$config->{host_mail_path}/$initial/$fqdn";
    my ($crypted, $user_id) = $class->get_user_from_file(
        $user_name,
        "$vdomain_dir/$config->{userlist}",
    );
    crypt($supplied_password, $crypted) eq $crypted;
}

sub get_userid_vdomain {
    my ($class, $config, $user_name, $fqdn, $supplied_password) = @_;
    my ($initial) = $fqdn =~ /^(.)/;
    my $vdomain_dir = "$config->{host_mail_path}/$initial/$fqdn";
    my ($crypted, $user_id) = $class->get_user_from_file(
        $user_name,
        "$vdomain_dir/$config->{userlist}",
    );
    $user_id;
}

# Get the user's crypt/crypt_MD5 password and numeric uid
sub get_user_from_file {
    my ($class, $user_name, $user_file) = @_;
    my ($crypted, $user_id);
    local *FH;
    open FH, $user_file or $class->force_shutdown("Could not open $user_file");
    while (<FH>) {
        if (/^$user_name:(.+?):(\d+):/) {
            $crypted = $1;
            $user_id = $2;
            last;
        }
    }
    close FH;
    return unless defined $crypted;
    ($crypted, $user_id);
}

1;
