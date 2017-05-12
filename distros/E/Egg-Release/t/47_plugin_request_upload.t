use Test::More;
use lib qw( ./lib ../lib );
use Egg::Helper;

unless ($ENV{EGG_UPLOAD_TEST}) {
	plan skip_all=> "I want setup of environment variable.";
} else {
	test();
}
sub test {

plan tests=> 49;

$ENV{REQUEST_METHOD} = 'POST';
$ENV{HTTP_USER_AGENT}= 'egg_request';

my $e= Egg::Helper->run( Vtest => {
  vtest_name=> 'UPLOAD',
  vtest_plugins=> [qw/ Request::Upload /],
  });

{
	no strict 'refs';  ## no critic.
	my %param= %{'Egg::View::Template::GlobalParam::param'};
	is $param{upload_enctype}, 'multipart/form-data',
	   q{$param{upload_enctype}, 'multipart/form-data'};
  };

my @files= $e->helper_yaml_load(join '', <DATA>);
$e->helper_create_files(\@files);

my $curdir= $e->helper_current_dir;

my $q= Egg::Helper->helper_http_request(
  qw{ POST /upload },
  Content_Type=> 'form-data',
  Content=> [
    param1 => 'test',
    upload1=> ["$curdir/data/upload.txt" ],
    upload2=> ["$curdir/data/upload.html"],
    ],
  );

$e->{request}= undef;

ok my $result= $e->helper_stdin( sub { $e->request }, $q ),
   q{my $result= $e->helper_stdin( ..... };
ok ! $result->error, q{! $result->error};
ok my $pm= $e->req->params, q{my $pm= $e->req->params};
ok $pm->{param1}, q{$pm->{param1}};
is $pm->{param1}, 'test', q{$pm->{param1}, 'test'};

can_ok $e->req, 'upload';
  ok my $up= $e->req->upload('upload1'),
     q{my $up= $e->req->upload('upload1')};

can_ok $up, 'name';
  is $up->name, 'upload1', q{$up->name, 'upload1'};

can_ok $up, 'handle';
  can_ok $up, 'fh';
  isa_ok $up->handle, 'Fh';

can_ok $up, 'catfilename';
  is $up->catfilename, 'upload.txt', q{$up->catfilename, 'upload.txt'};

can_ok $up, 'copy_to';
  ok $up->copy_to("$curdir/up.txt"), q{$up->copy_to("$curdir/up.txt")};
  ok -e "$curdir/up.txt", q{-e "$curdir/up.txt"};

can_ok $up, 'link_to';
  ok $up->copy_to("$curdir/up_link.txt"), q{$up->copy_to("$curdir/up_link.txt")};
  ok -e "$curdir/up_link.txt", q{-e "$curdir/up_link.txt"};

can_ok $up, 'filename';
  like $up->filename, qr{upload\.txt$}, q{$up->filename, qr{upload\.txt$}};

can_ok $up, 'tempname';
  ok -e $up->tempname, q{-e $up->tempname};

can_ok $up, 'size';
  is $up->size, length($files[0]{value}), q{$up->size, length($files[0]{value})};

can_ok $up, 'type';
  is $up->type, 'text/plain', q{$up->type, 'text/plain'};

can_ok $up, 'info';
  isa_ok $up->info, 'HASH';
  like $up->info->{'Content-Disposition'}, qr{^form\-data\;\s.+},
     q{$up->info->{'Content-Disposition'}, qr{^form\-data\;\s.+}};
  like $up->info->{'Content-Type'}, qr{text/plain},
     q{$up->info->{'Content-Type'}, qr{text/plain}};

ok $up= $e->req->upload('upload2'),
     q{$up= $e->req->upload('upload2')};
is $up->name, 'upload2', q{$up->name, 'upload2'};
can_ok $up, 'fh';
isa_ok $up->handle, 'Fh';
is $up->catfilename, 'upload.html', q{$up->catfilename, 'upload.html'};
ok $up->copy_to("$curdir/up.html"), q{$up->copy_to("$curdir/up.html")};
ok -e "$curdir/up.html", q{-e "$curdir/up.html"};
ok $up->copy_to("$curdir/up_link.html"), q{$up->copy_to("$curdir/up_link.html")};
ok -e "$curdir/up_link.html", q{-e "$curdir/up_link.html"};
like $up->filename, qr{upload\.html$}, q{$up->filename, qr{upload\.html$}};
ok -e $up->tempname, q{-e $up->tempname};
is $up->size, length($files[1]{value}), q{$up->size, length($files[1]{value})};
is $up->type, 'text/html', q{$up->type, 'text/html'};
isa_ok $up->info, 'HASH';
like $up->info->{'Content-Disposition'}, qr{^form\-data\;\s.+},
   q{$up->info->{'Content-Disposition'}, qr{^form\-data\;\s.+}};
like $up->info->{'Content-Type'}, qr{text/html},
   q{$up->info->{'Content-Type'}, qr{text/html}};

}

__DATA__
---
filename: data/upload.txt
value: |
  test123
---
filename: data/upload.html
value: |
  <html>
  <body>test123</body>
  </html>
