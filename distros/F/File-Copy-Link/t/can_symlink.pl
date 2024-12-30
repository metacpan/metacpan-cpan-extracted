my $symlink_message;

sub skip_symlink_message { return $symlink_message; }

sub has_symlink {
    return 1 if eval { symlink( q{}, q{} ), 1; };
    $symlink_message = q{symlink() not implemented};
    return;
}

sub can_symlink {
    return   unless has_symlink();
    return 1 unless is_windows();
    return 1 if $Win32::IsSymlinkCreationAllowed;
    $symlink_message = q{symlink creation not allowed};
    return;
}

sub is_windows {    # from File::Rename t/testlib.pl
    unless ( $] < 5.014 ) {
        if ( eval { require Perl::OSType; } ) {
            return Perl::OSType::is_os_type('Windows');
        }
        diag $@;
    }
    return ( $^O eq q{MSWin32} );
}

1;
