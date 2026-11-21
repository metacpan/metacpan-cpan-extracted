package HTTP::API::Core::Example::Jira;

use strict;
use warnings;
use parent 'HTTP::API::Core';
use HTTP::API::Core::Auth qw(basic_auth);

# A small Jira Server/Data Center search recipe, not an official SDK.
sub new {
    my ($class, %args) = @_;
    my $username = delete $args{username};
    my $password = delete $args{password};
    die "username is required\n" if !defined($username) || ref($username) ne '';
    die "password is required\n" if !defined($password) || ref($password) ne '';
    die "base_url is required\n" if !defined($args{base_url});
    die "custom hooks are not supported by this example\n"
        if exists $args{hooks};

    return $class->SUPER::new(
        %args,
        hooks => { before_request => basic_auth($username, $password) },
    );
}

sub issues_pager {
    my ($self, %args) = @_;
    my $jql = delete $args{jql};
    die "jql must be a non-empty scalar\n"
        if !defined($jql) || ref($jql) ne '' || $jql eq '';

    my $fields = delete $args{fields};
    if (defined $fields) {
        if (ref($fields) eq 'ARRAY') {
            die "fields must contain only non-empty scalars\n"
                if grep { !defined($_) || ref($_) ne '' || $_ eq '' } @$fields;
            $fields = join(',', @$fields);
        }
        elsif (ref($fields) ne '') {
            die "fields must be a string or array reference\n";
        }
    }

    my $max_results = exists($args{max_results})
        ? delete($args{max_results}) : 100;
    die "unknown issues_pager option: $_\n" for sort keys %args;

    return $self->paginate(
        '/rest/api/2/search',
        mode            => 'offset',
        items           => 'issues',
        total           => 'total',
        offset_param    => 'startAt',
        page_size_param => 'maxResults',
        page_size       => $max_results,
        query           => {
            jql => $jql,
            (defined($fields) ? (fields => $fields) : ()),
        },
    );
}

1;
