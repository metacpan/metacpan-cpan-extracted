# use Carp qw(verbose);

use Test::More qw/ no_plan /;

SKIP:
{
    # tests the new object test supplied by Dan Horne (RT #18129)
    # specifically with CGI.
    # Note that CGI.pm prior to version 3.06 does not have a sane
    # can() method, so we skip this test if your version is older.

    require CGI;
    skip "Your CGI.pm ($CGI::VERSION) does not have a sane can() method. Upgrade to at least 3.06 if you want to run this test." if $CGI::VERSION lt '3.06';
    
    BEGIN {
        $ENV{QUERY_STRING} = 'foo=bar';
        $ENV{HTTP_HOST} = 'hiero';
        $ENV{CGI_APP_RETURN_ONLY} = 1;
    }

    my $t = T2->new;
    $t->start_mode('foo');
    my $out = $t->run;
    like ($out, qr/Start Mode: foo/);

    package T2;
    use warnings;
    use HTML::Template::Pluggable;
    use HTML::Template::Plugin::Dot;

    sub new { bless {}, +shift; }
    sub run { my $self = shift; my $m = $self->{start_mode}; $self->$m(); }
    sub start_mode { my $self = shift; $self->{start_mode} = shift if @_; $self->{start_mode} }
    sub query { my $self = shift; $self->{cgi} ||= CGI->new; $self->{cgi}; }
    sub foo {
        my $self = shift;
        my $t = HTML::Template::Pluggable->new(scalarref => \q{
            <tmpl_var 'c.query.start_html("foo")'>
            Start Mode: <tmpl_var c.start_mode>
        });
        $t->param(c => $self);
        return $t->output;
    }
}

__END__
