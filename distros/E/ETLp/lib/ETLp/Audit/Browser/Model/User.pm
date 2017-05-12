package ETLp::Audit::Browser::Model::User;

use MooseX::Declare;

class ETLp::Audit::Browser::Model::User with(ETLp::Role::Config, ETLp::Role::Schema, ETLp::Role::Audit,     ETLp::Role::Browser) {
        
    use Crypt::PasswdMD5 'unix_md5_crypt';
    use Data::Dumper;
        
    method get_user_by_username(Str $username) {
        return $self->EtlpUser->single({username => $username});
    }
        
    method get_user(Maybe[Int] $user_id?) {
        return $self->EtlpUser->find($user_id);
    }
    
    method get_users(Int :$page = 1) {
        return $self->EtlpUser->search(
            undef,
            {
                page     => $page,
                order_by => 'first_name, last_name',
                rows     => $self->pagesize,
            }
        );
    }
    
    method save(HashRef $params) {    
        delete $params->{password2} if $params->{password2};
        $params->{password} = $self->encrypt_password($params->{password})
          if $params->{password};
    
        $params->{admin}  = 0 unless $params->{admin};
        $params->{active} = 0 unless $params->{active};
    
        $self->logger->debug('Paramters to save: ' . Dumper($params));
        return $self->EtlpUser->update_or_create($params);
    }
    
    method generate_salt {
        my @chars = ('.', '/', 0 .. 9, 'A' .. 'Z', 'a' .. 'z');
        my $length = rand(8);
        my $salt;
    
        $salt .= (@chars)[rand @chars] for (1 .. $length);
    
        return $salt;
    }
    
    method encrypt_password(Str $password) {
        return unix_md5_crypt($password, $self->generate_salt);
    }
    
    method check_password(Str $plaintext_password, Str $encrypted_password) {    
        my $salt = (split(/\$/, $encrypted_password))[2];    
        return (unix_md5_crypt($plaintext_password, $salt) eq
                $encrypted_password);
    }
    
    method update_password(Str $password, Int $user_id) {
        my $user     = $self->EtlpUser->find($user_id);
        $user->password($self->encrypt_password($password));
        $user->update;
    }
}
     
=head1 NAME

ETLp::Audit::Browser::Model::User - Model Class for interacting
with Runtime FileProcess User Records

=head1 SYNOPSIS

    use ETLp::Audit::Browser::Model::User;
    
    my $model = ETLp::Audit::Browser::Model::User->new();
    my $processes = $model->get_user_by_username('jbloggs');
    
=head1 METHODS

=head2 get_user_by_username

Returns an etlp_user record given the username

=head3 Parameters
 
    * username. Required. The name of the user
    
=head3 Returns

    * A DBIx::Class record
    
=head2 get_user

Returns an etlp_user record given the user id

=head3 Parameters
 
    * username. Required. The name of the user
    
=head3 Returns

    * A DBIx::Class record
    
=head2 get_users

Returns the users one page at a time 

=head3 Parameters
 
    * page. optional. The page being requested. Defaults to 1
    
=head3 Returns

    * A DBIx::Class resultset
    
=head2 save

Saves user input 

=head3 Parameters

A hashref consisting of 
 
    * user_id
    * username
    * first_name
    * last_name
    * password (optional), unencrypted
    * password2 (optional), unencrypted
    * email_address (optional)
    * admin (optional, 1= admin 0 = not admin)
    * active (optional, 1 = active, 0 = inactive)
    
=head3 Returns

    * A DBIx::Class resultset

=head2 generate_salt

Returns a salt that is used in the password encrytion routine

=head3 Parameters

    * None
    
head3 Returns

    * Up to eight characters (from Lower and upper case letters,
      digits period, slash)    

=head2 encrypt_password

Encrypts plaint test text password

=head3 Parameters

    * password. String.
    
=head3 Returns

    * encrypted password
    
=head2 check_password

Checks whether the exncrypted plaintext password will match the actual
encrypted password

=head3 Parameters

    * paintext_password. String. Mandatory.
    * encrypted_password. String. Mandatory. The encrypted password
    
=head3 Returns

    * Void
    
=head2 update_password

Update a user's password

=head3 Parameters

    * password. String. Mandatory. The plaintext password
    * user_id. Integer. Mandatory. The user updating this record.
    
=head3 Returns

    * Void
    
=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application

=cut