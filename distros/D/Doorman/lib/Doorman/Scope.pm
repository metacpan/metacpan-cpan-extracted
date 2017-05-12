package Doorman::Scope;
use strict;
use Plack::Util::Accessor qw(name root_url);
use URI;

sub new {
    my $class = shift;
    return bless { root_url => "http://localhost", name => "users", @_ }, $class;
}

sub scope_url  {
    $_[0]->root_url . '/' . $_[0]->name;
}

sub scope_path  {
    return URI->new($_[0]->scope_url)->path;
}

for my $x (qw(in out)) {
    no strict 'refs';

    *{ __PACKAGE__ . "::sign_${x}_url" } = sub {
        return $_[0]->scope_url . "/sign_${x}";
    };

    *{ __PACKAGE__ . "::sign_${x}_path" } = sub {
        my $method = "sign_${x}_url";
        return URI->new($_[0]->$method)->path;
    };
}

1;

=head1 NAME

Doorman::Scope

=head1 DESCRIPTION

C<Doorman::Scope> objects are responsible to generate URLs and PATHs that are handled
by Doorman middlewares.

=head1 ATTRIBUTES

Attributes can be given in the constructor C<new> as a hash:

    my $scope = Doorman::Scope->new( name => "members", root_url => "http://example.com" );

Or set afterwards by using their accessor methods:

    my $scope = Doorman::Scope->new;
    $scope->name("members");
    $scope->root_url("http://example.com");

=over 4

=item name

Default C<"users">. The scope name used to generate PATHs. The "users" scope name
generates PATHs prefixed "/users". Specifically they are:

    /users
    /users/sign_in
    /users/sign_out

Depending on different app requirements, you might sometimes need to
avoid the use of "/users" PATH. You can change the scope to
, say, C<"members"> to generate these URLs:

    /members
    /members/sign_in
    /members/sign_out

=item root_url

Default "http://localhost". This is the App root url. Many modern web apps
take just a domain without path part, like C<http://hiveminder.com> or
C<http://gmail.com>. Usually you do not need to tweak this value, the middleware
can guess it from the request environment. However, if your app lives unders some
given PATH, you may set this to something like C<"http://mydomain.com/myapp>".

=back

=head1 METHODS

=over 4

=item sign_in_path

Returns a string of the sign-in path.

=item sign_out_path

Returns a string of the sign-out path.

=item sign_in_url

Returns a string of the full URL to sign in.

=item sign_out_url

Returns a string of the full URL to sign out.

=back

=cut
