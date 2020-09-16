package HealthCheck::Diagnostic::FilePermissions;
use parent 'HealthCheck::Diagnostic';

# ABSTRACT: Check the paths for expected permissions in a HealthCheck
use version;
our $VERSION = 'v1.4.8'; # VERSION

use strict;
use warnings;

use Carp;

sub new {
    my ($class, @params) = @_;

    my %params = @params == 1 && ( ref $params[0] || '' ) eq 'HASH'
        ? %{ $params[0] } : @params;

    return $class->SUPER::new(
        id    => 'file_permissions',
        label => 'File Permissions',
        %params,
    );
}

sub collapse_single_result {
    my ($self, @args) = @_;
    return $self->SUPER::collapse_single_result(@args)
        if ref $self and exists $self->{collapse_single_result};

    # If we are only checking a single parameter on a single file,
    # the additional level of results is useless here.
    return 1;
}

sub check {
    my ($self, %params) = @_;

    # Make it so that the diagnostic can be used as an instance or a
    # class, and the `check` params get preference.
    if ( ref $self ) {
        $params{$_} = $self->{$_}
            foreach grep { ! defined $params{$_} } keys %$self;
    }

    # Allow the files to be either an anonymous sub, an array, or a
    # string of the filename(s).
    if ( ref $params{files} eq 'CODE' ) {
        $params{files} = [ $params{files}->() ];
    }
    elsif ( defined $params{files} and ref $params{files} ne 'ARRAY' ) {
        # Passed-in strings can only be one file name.
        $params{files} = [ $params{files} ];
    }
    croak( 'No files extracted' ) unless @{ $params{files} || [] };

    # Convert the access parameter into a r/w/x hash if it is not already
    # a hash. Then convert that into a read/write/execute hash.
    my %access;
    if ( ref $params{access} ne 'HASH' ) {
        # Everything to the left of the exclamation point is regarded as
        # expecting an enabled permission. Everything to the right is
        # regarded as expecting a disabled permission.
        my ($enabled, $disabled) = split( '!', $params{access} || '' );
        $params{access} = {
                ( map { $_ => 1 } split //, $enabled || '' ),
                ( map { $_ => 0 } split //, $disabled || '' ),
        };
    }
    my %map = (
        r       => 'read',
        read    => 'read',
        w       => 'write',
        write   => 'write',
        x       => 'execute',
        execute => 'execute',
    );
    foreach ( keys %{ $params{access} || {} } ) {
        croak( "Invalid access parameter: $_" )
            unless defined $map{$_};
        $access{ $map{$_} } = $params{access}->{$_};
    }
    $params{access} = \%access;

    return $self->SUPER::check(%params);
}

sub run {
    my ( $self, %params ) = @_;

    my @results;
    foreach my $file ( @{ $params{files} } ) {
        my @file_results;
        if ( ! -e $file ) {
            # Don't attempt to look for permissions if the file does
            # not exist.
            push @results, {
                info   => qq{'$file' does not exist},
                status => 'CRITICAL',
            };
            next;
        }
        push @file_results,
            $self->check_access( $file, $params{access} )
            if %{ $params{access} };
        push @file_results,
            $self->check_permissions( $file, $params{permissions} )
            if defined $params{permissions};
        push @file_results,
            $self->check_owner( $file, $params{owner} )
            if defined $params{owner};
        push @file_results,
            $self->check_group( $file, $params{group} )
            if defined $params{group};

        # Add a default result if there were no permissions to check
        # for the file.
        push @file_results, {
            info   => qq{'$file' exists},
            status => 'OK',
        } unless @file_results;

        push @results, @file_results;
    }

    # Construct the main info statement for the check, which consists
    # of the failed info messages.
    my @info = map { $_->{info} } grep { $_->{status} ne 'OK' } @results;

    # Use a default success message if no fail info messages were found.
    push @info, 'Permissions are correct for '.
        $self->pretty_join( map { qq{'$_'} } @{ $params{files} } )
        unless @info;

    return { info => join( '; ', @info ), results => \@results };

}

sub pretty_join {
    my ($self, @list) = @_;

    # Join the list items with a command and final 'and'.
    return $list[0] if @list == 1;
    $list[ $#list ] = 'and '.$list[ $#list ];
    return join( ' ', @list ) if @list == 2;
    return join( ', ', @list );
}

sub check_access {
    my ($self, $file, $access) = @_;

    # Run the tests and construct the error messages, identifying which
    # access operation failed.
    my $info = "Permissions for '$file':";
    my @access_errors;
    my %actual = (
        read    => -r $file,
        write   => -w $file,
        execute => -x $file,
    );
    foreach ( sort keys %$access ) {
        push @{ $access_errors[ $access->{$_} ] }, $_
            if $access->{$_} xor $actual{$_};
    }

    # Return a default success access permission info message if it found
    # no errors.
    return {
        status => 'OK',
        info   => qq{Have correct access for '$file'},
    } unless @access_errors;

    # Summarize the failed info messages in the results.
    my @info;
    push @info, 'Must have permission to '.
        $self->pretty_join( @{ $access_errors[1] } ).qq{ '$file'}
        if @{ $access_errors[1] || [] };
    push @info, 'Must not have permission to '.
        $self->pretty_join( @{ $access_errors[0] } ).qq{ '$file'}
        if @{ $access_errors[0] || [] };
    return {
        status => 'CRITICAL',
        info   => join( '; ', @info ),
    };
}

sub check_permissions {
    my ($self, $file, $permissions) = @_;

    # Stringify the expected and actual permissions so that they can be
    # easily understood.
    my $actual   = sprintf( '%04o', ( stat($file) )[2] & 07777 );
    my $expected = sprintf( '%04o', $permissions & 07777 );

    return {
        status => 'CRITICAL',
        info   => "Permissions should be $expected but ".
            "are $actual for '$file'",
    } if $expected != $actual;

    return {
        status => 'OK',
        info   => qq{Permissions are $actual for '$file'},
    };
}

sub check_owner {
    my ($self, $file, $owner) = @_;

    my $actual = getpwuid( ( stat $file )[4] );
    return {
        status => 'CRITICAL',
        info   => qq{Owner should be $owner but is $actual for '$file'},
    } unless $actual eq $owner;

    return {
        status => 'OK',
        info   => qq{Owner is $owner for '$file'},
    };
}

sub check_group {
    my ($self, $file, $group) = @_;

    my $actual = getgrgid( ( stat $file )[5] );
    return {
        status => 'CRITICAL',
        info   => qq{Group should be $group but is $actual for '$file'},
    } unless $actual eq $group;

    return {
        status => 'OK',
        info   => qq{Group is $group for '$file'},
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HealthCheck::Diagnostic::FilePermissions - Check the paths for expected permissions in a HealthCheck

=head1 VERSION

version v1.4.8

=head1 SYNOPSIS

    use HealthCheck::Diagnostic::FilePermissions;

    # Just check that a file exists, without instantiating anything.
    HealthCheck::Diagnostic::FilePermissions->check(
        files => [ '/tmp', '/other_directory' ],
    );

    # Check that some files have certain permissions.
    my $d = HealthCheck::Diagnostic::FilePermissions->new(
        files => [ '/tmp', '/var/nfs' ],
    );
    $d->check( permissions => 0777 );

    # Check that it has access to the file(s).
    $d->check( access => 'x' );    # Can execute files.
    $d->check( access => 'rw' );   # Can read and write files.
    $d->check( access => 'r!wx' ); # Can read, not write and execute files.
    $d->check( access => {         # Can read files.
        read => 1,
    } );

    # Check the owner and group of the file.
    $d->check( owner => 'owner_name', group => 'group_name' );

    # Any combination of parameters can be used.
    $d->check(
        permissions => 07777,
        access      => 'rwx',
        owner       => 'dveres',
    );

=head1 DESCRIPTION

This diagnostic allows a process to test file permissions on the system.
You can specify a list of files and then the expected permissions
code for the group.
Additionally, you can specify access permissions for the process that
is running the script.

=head1 ATTRIBUTES

=head2 files

Represents the file names of the files that are checked for the defined
I<permissions>.

There are a few forms that this attribute can take up.
The first is a string, which can represent one file path to check.
The value can also be a list of file paths to check.
Finally, this value can also be an anonymous sub and return a list of
file paths to check.

    files => "$filename"
    files => [ $filename1, $filename2 ],
    files => sub { $filename1, 'other_file_name' }

=head2 access

The access permissions of the process executing the code.
This attribute can take two forms, a I<HASH> and C<SCALAR>.

The hash form includes I<read>, I<write>, and I<execute> values, which
represent if the process can perform that action on the file.
Shortcut keys such as I<r>, I<w>, and I<x> can also be used.

The scalar form is a string that consists of the read/write/execute values
in their short form (Ex: I<r> for I<read>, I<w> for I<write>, and I<x>
for I<execute>).
One exclamation point is used to separate the allowed and denied access
on the files.

Any access permissions that are not defined are just ignored.

    # Expect that it can read, write, and execute the file(s).
    access => 'rwx'
    access => { r    => 1, w     => 1, x       => 1 }
    access => { read => 1, write => 1, execute => 1 },

    # Expect that it cannot read, write, or execute the file(s).
    access => '!rwx'
    access => { r    => 0, w     => 0, x       => 0 }
    access => { read => 0, write => 0, execute => 0 }

    # Expect that it can read but not write, nor execute the file(s).
    access => 'r!wx'
    access => { r    => 1, w     => 0, x       => 0 }
    access => { read => 1, write => 0, execute => 0 }

    # Expect that it can read, but ignore other access permissions.
    access => 'r'
    access => { r    => 1 }
    access => { read => 1 }

=head2 permissions

The octal value of the permissions on the file (or files).

    # User can read, write, and execute the file(s).
    permissions => 0700

    # Nobody can read, write, or execute the file(s).
    permissions => 0000

=head2 owner

The owner name of the file (or files).

    owner => 'bmessine'

=head2 group

The group name of the file (or files).

    group => 'developers'

=head2 collapse_single_result

The default for L<HealthCheck::Diagnostic/collapse_single_result>
is changed to be truthy.

This only has an effect if checking a single attribute of a single file.

=head1 DEPENDENCIES

L<HealthCheck::Diagnostic>

=head1 CONFIGURATION AND ENVIRONMENT

None

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 - 2020 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
