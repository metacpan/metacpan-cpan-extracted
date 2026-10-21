use v5.10; use strict; use warnings;
use Test::More;
use lib 't/lib'; use TWK; TWK::skip_unless_available();
use EV; use EV::WebKit;

my $b = EV::WebKit->new(window => [400,300], timeout => 5);
my ($submitted, $submit_tick);
$b->mock_scheme('frameform', sub {
    $submitted = $_[0];
    $submit_tick = EV::timer(0, 0, sub { undef $submit_tick; EV::break });
    return ('<p>submitted</p>', 'text/html');
});

my $fixture = q{<iframe id=f srcdoc='<form id=form action="frameform://host/sent">}
            . q{<input name=answer value=42><input name=submit>}
            . q{<select id=sel><option value=a>A</option><option value=b>B</option></select>}
            . q{<input id=check type=checkbox></form>'></iframe>};
my %got;
$b->load_html($fixture, sub {
    is($_[1], undef, 'frame fixture loaded');
    $b->find('#sel', frame => '#f', sub {
        my ($select, $err) = @_;
        ok($select && !$err, 'select found through a frame selector');
        return EV::break unless $select;
        $select->select_option('b', sub {
            @got{qw(selected select_err)} = @_;
            $b->find('#check', frame => '#f', sub {
                my ($check) = @_;
                return EV::break unless $check;
                $check->check(sub {
                    @got{qw(checked check_err)} = @_;
                    $b->script(q{
                        const d = document.querySelector('#f').contentDocument;
                        return [d.querySelector('#sel').value, d.querySelector('#check').checked];
                    }, sub {
                        $got{state} = $_[0];
                        $b->find('#form', frame => '#f', sub {
                            my ($form) = @_;
                            return EV::break unless $form;
                            $form->submit(sub { @got{qw(submit_ok submit_err)} = @_ });
                        });
                    });
                });
            });
        });
    });
});
my $deadline = EV::timer(8, 0, sub { EV::break });
EV::run;
undef $deadline;
is($got{select_err}, undef, 'select_option accepts a control in another frame');
is($got{selected}, 'b', 'select_option returns its value');
is($got{check_err}, undef, 'check accepts a control in another frame');
ok($got{checked}, 'check reports checked');
is_deeply($got{state}, ['b', Cpanel::JSON::XS::true()], 'frame controls actually changed');
is($got{submit_err}, undef, 'submit answers without an error');
like($submitted // '', qr{^frameform://host/sent\?answer=42}, 'submit actually sends the frame form');
$b->quit;
done_testing;
