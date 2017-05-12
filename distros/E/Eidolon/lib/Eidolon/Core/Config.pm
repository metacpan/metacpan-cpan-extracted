package Eidolon::Core::Config;
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   Eidolon/Core/Config.pm - system config
#
# ==============================================================================

use FindBin;
use warnings;
use strict;

our ($VERSION, $INSTANCE);

$VERSION  = "0.02"; # 2009-05-14 04:54:08
$INSTANCE = undef;

# ------------------------------------------------------------------------------
# \% new($name, $type)
# constructor
# ------------------------------------------------------------------------------
sub new
{
    my ($class, $name, $type, $self);

    ($class, $name, $type) = @_;

    # class attrubutes
    $self = 
    { 
        # application settings
        "app" =>
        {
            "title"   => undef,
            "name"    => $name,
            "version" => $name->VERSION,
            "root"    => $FindBin::Bin,
            "lib"     => $FindBin::Bin."/lib",
            "type"    => $type,
            "policy"  => "private",
            "error"   => [ "Eidolon::Error", "error" ]
        },

        # CGI settings
        "cgi" => 
        {
            "max_post_size"  => 600000,
            "tmp_dir"        => "/tmp/",
            "charset"        => "UTF-8",
            "content_type"   => "text/html",
            "session_cookie" => "SESSIONID",
            "session_time"   => 3600
        },

        # driver list
        "drivers" => []
    };

    bless $self, $class;
    $INSTANCE = $self;

    return $self;
}

# ------------------------------------------------------------------------------
# \% get_instance()
# get config instance
# ------------------------------------------------------------------------------
sub get_instance
{
    return $INSTANCE;
}

1;

__END__

=head1 NAME

Eidolon::Core::Config - generic configuration of the Eidolon application.

=head1 SYNOPSIS

Example application configuration (C<lib/Example/Config.pm>):

    package Example::Config;
    use base qw/Eidolon::Core::Config/;

    our $VERSION  = "0.01";

    sub new
    {
        my ($class, $name, $type, $self);

        ($class, $name, $type) = @_;

        $self = $class->SUPER::new($name, $type);
        $self->{"app"}->{"title"} = "Example application";

        $self->{"drivers"} = 
        [
            {
                "class" => "Eidolon::Driver::Router::Basic"
            }
        ];

        return $self;
    }

=head1 DESCRIPTION

The I<Eidolon::Core::Config> class holds common configuration for all 
I<Eidolon> applications. Each application configuration should inherit 
this class and redefine generic parameters. This class should never be used 
directly.

=head2 Application configuration section

Main application settings are specified in C<{"app"}> item of configuration 
hash. This item contains a hashref of application settings:

=over 4

=item * title

Application title. Affects nothing, but could be useful in application design.

=item * name

Application class name. Determined automatically, you should not change this 
manually, otherwise something strange and bad can happen.

=item * version

Application version. Affects nothing, but could be useful sometimes. Value is
inserted automatically, if your C<Application.pm> has C<our $VERSION> variable
defined.

=item * root

Application root directory. Determined automatically by getting the 
C<$FindBin::Bin> value (see L<FindBin> for more information). You can redefine 
this manually, if you need. This value isn't used by the Eidolon core.

=item * lib

Application library path. Determined automatically by getting the 
C<$FindBin::Bin> value (see L<FindBin> for more information). You can redefine 
this manually, if you need. This value isn't used by the Eidolon core.

=item * type

Application type. Is determined automatically. I<Do not change it manually>!

=item * policy

Application security policy. Can have two possible values: I<public> or 
I<private>. The default is I<private>. In I<public> application anyone can
view any page, if page isn't marked as I<private> explicitly. In I<private>
application only authorized users can view pages, if page method isn't marked as 
I<public>.

=item * error

Application error handler. Is an array reference, first item of array is a class
name and the second item is a subroutine name of the error handler. By default,
all application errors are handled by the L<Eidolon::Error> package. Obviously, 
you will want to set your own error handler, so you should change this value.

=back 

=head2 CGI configuration section

CGI settings are specified in C<{"cgi"}> item of configuration hash. This item 
contains a hashref of CGI settings:

=over 4

=item * max_post_size

Maximal POST request length, in bytes. The default value is I<600000>.

=item * tmp_dir

Directory path for saving temporary files and session data. The default value 
is I</tmp/>.

=item * charset        

General application charset. The default value is I<UTF-8>.

=item * content_type

General application content type. The default value is I<text/html>.

=item * session_cookie

Application session cookie name. The default value is I<SESSIONID>.

=item * session_time

Session lifetime (in seconds). The default value is 3600 (1 hour).

=back

=head2 Drivers configuration section

Drivers configuration is specified in C<{"drivers"}> item of a configuration 
hash. This item is the reference to array of hashrefs, each hashref represents
one driver configuration. Hashref items are:

=over 4

=item * class

Driver class name. 

=item * params

Reference to array of driver initialization parameters. This parameters will be
sent to a driver constructor during driver initialization. 

=back

=head1 METHODS

=head2 new($name, $type)

Class constructor. Creates generic configuration for application C<$name> of
C<$type> type.

=head2 get_instance()

Returns configuration instance. Class must be instantiated first.

=head1 SEE ALSO

L<Eidolon>, L<Eidolon::Application>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Anton Belousov, E<lt>abel@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2009, Atma 7, L<http://www.atma7.com>

=cut
