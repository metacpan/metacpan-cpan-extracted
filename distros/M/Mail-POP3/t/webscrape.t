use strict;
use Test::More;

use File::Temp;

use_ok 'Mail::POP3';
use_ok 'Mail::POP3::Folder::webscrape';

my %CONFIG = (
  msgid1 => '928F11260DD14DF7@jobserve.com',
  msgid2 => 'B1D9F6EA1A27AE23@jobserve.com',
  msgid3 => '9B214739A40DA63B@jobserve.com',
  URL2INFO => {
    'http://www.jobserve.com/gb/en/Job-Search/' => {
      real_url => 'http://www.jobserve.com/gb/en/Job-Search/',
      html => <<HTML,
<form name="frm1" method="post" action="FindYourNextJob.aspx" id="frm1">
<input type=submit>
</form>
HTML
    },
    'http://www.jobserve.com/gb/en/Job-Search/FindYourNextJob.aspx' => {
      real_url => 'http://www.jobserve.com/gb/en/JobListingBasic.aspx?shid=B930BDCD4DFA8661D9',
      html => <<HTML,
<span class="Small onpagehighlight">1</span>
<a href="page.asp?page=2" title="Last Page">Last</a>
<a href="JobListingBasic.aspx?shid=B930BDCD4DFA8661D9&page=2" title="Next Page">Next</a>
<a href="/gb/en/W928F11260DD14DF7.jsjob" class="jobListPosition">job 1</a>
<a href="/gb/en/WB1D9F6EA1A27AE23.jsjob" class="jobListPosition">job 2</a>
HTML
    },
    'http://www.jobserve.com/gb/en/JobListingBasic.aspx?shid=B930BDCD4DFA8661D9&page=2' => {
      real_url => 'http://www.jobserve.com/gb/en/JobListingBasic.aspx?shid=B930BDCD4DFA8661D9&page=2',
      html => <<HTML,
<span class="Small onpagehighlight">2</span>
<a href="page.asp?page=2" title="Last Page">Last</a>
<a href="JobListingBasic.aspx?shid=B930BDCD4DFA8661D9&page=2" title="Next Page">Next</a>
<a href="/gb/en/W9B214739A40DA63B.jsjob" class="jobListPosition">job 3</a>
HTML
    },
    'http://www.jobserve.com/gb/en/W928F11260DD14DF7.jsjob' => {
      real_url => 'http://www.jobserve.com/gb/en/search-jobs-in-London,-London,-United-Kingdom/PERL-DEVELOPER-928F11260DD14DF7/',
      html => <<HTML,
<div itemprop="title">Perl Developer</div>
<span itemprop="employmentType">Permanent</span>
<div itemprop="description"><P>Perl Developer<BR>Location: London, W12<BR>Business: NET-A-PORTER GROUP<BR>Hours of Work: 37.5 hours per week</P></div>
<span itemprop="addressLocality">London, UK</span>
<span itemprop="industry"><a href="/gb/en/IT+Telecommunications-sector-jobs-in-United-Kingdom/">IT</a></span>
<span itemprop="name">Net-A-Porter Group LTD</span>
<label id="lbl_recruiter">Company</label>
<span id="md_contact">Recruitment Team</span>
<span id="md_ref">JSPERL DEVELOPER</span>
<span id="md_posted_date">03/01/2014 09:33:47</span>
<a id="md_permalink">http://www.jobserve.com/DG5QB</a>
HTML
    },
  },
  MESSAGESIZE => 1000,
  messagelines => 5,
  messagetext => <<'EOF',
To: madeup@example.com
From: madeup@example.com
Subject: Perl Developer - Jobserve ref JSPERL DEVELOPER
Message-ID: 928F11260DD14DF7@jobserve.com
Date: Fri, 03 Jan 2014 09:33:47 GMT (GMT)
MIME-Version: 1.0
Content-Type: text/html; charset=utf-8
Content-Transfer-Encoding: quoted-printable

<h1>Permanent: Perl Developer</h1>
<p>
<P>Perl Developer<BR>Location: London, W12<BR>Business: NET-A-PORTER GROUP<=
BR>Hours of Work: 37.5 hours per week</P>
</p>
<p>
Location: London, UK<br>
Salary/Rate: <br>
Company: Net-A-Porter Group LTD<br>
Contact: Recruitment Team<br>
Telephone: <br>
E-Mail: <br>
Reference: JSPERL DEVELOPER<br>
Posted Date: 03/01/2014 09:33:47<br>
Job listing: <a href=3D"http://www.jobserve.com/DG5QB">http://www.jobserve.=
com/DG5QB</a><br>
</p>
EOF
);

# in: $cookiejar, $http_request
# out: $html, $real_url
undef *Mail::POP3::Folder::webscrape::redirect_cookie_loop;
*Mail::POP3::Folder::webscrape::redirect_cookie_loop = sub {
  my ($cookiejar, $r) = @_;
  my $info = $CONFIG{URL2INFO}->{$r->uri};
  die "Unknown URI:" . $r->uri . "\n" unless $info;
  ($info->{html}, $info->{real_url});
};

sub makere { # element, attributename, attributevalue
    "<$_[0]\[^>]+?$_[1]=['\"]?$_[2]\['\"]?[^>]*?>(.*?)</$_[0]>";
}

my $mailbox = Mail::POP3::Folder::webscrape->new(
    'perl:Zanzibar:5',
    'password',
    'http://www.jobserve.com/gb/en/Job-Search/',
    [ qw(
      ctl00$main$srch$ctl_qs$txtKey
      ctl00$main$srch$ctl_qs$txtLoc
      selRad
    ) ],
    +{
      selInd => '00',
      'ctl00$main$srch$ctl_qs$txtTitle' => '',
      selAge => '7',
      selJType => '15',
    },
    {
      pageno => '<span[^>]+class="Small\s+onpagehighlight"[^>]*?>(.*?)</span>',
      num_pages => '<a[^>]+href=".*?page=(\d+)" title="Last Page"',
      nextlink => '<a[^>]+href="([^"]*)" title="Next Page"',
      itemurls => '<a href="([^"]+)"[^>]+class="jobListPosition"',
    },
    +{
      title => makere(qw(div itemprop title)),
      type => makere(qw(span itemprop employmentType)),
      description => makere(qw(div itemprop description)),
      location => makere(qw(span itemprop addressLocality)),
      industry => makere(qw(span itemprop industry)),
      rate => makere(qw(span id md_rate)),
      recruiter => makere(qw(span itemprop name)),
      recruitertype => makere(qw(label id lbl_recruiter)),
      recruiterlink => makere(qw(span id md_weblink)),
      contact => makere(qw(span id md_contact)),
      telephone => makere(qw(span id md_telephone)),
      email => makere(qw(span id md_email)),
      reference => makere(qw(span id md_ref)),
      posted => makere(qw(span id md_posted_date)),
      joblink => makere(qw(a id md_permalink)),
    },
    +{
      # sub that returns list of key => value
      # might be more than one pair
      email => sub { $_[1] =~ s#.*mailto:(.*?)\?.*#$1#si; @_; },
      contact => sub { $_[1] =~ s#\s*<a.*##i; @_; },
      recruiterlink => sub { $_[1] =~ s#<.*?>##g; @_; },
      industry => sub { $_[1] =~ s#<.*?>##g; @_; },
    },
# use Carp;Carp::cluck "X";
    sub { ($_[0] =~ m#/W([^-]+)\.jsjob$#)[0] . '@jobserve.com'; },
    sub {
      use POSIX qw(strftime locale_h);
      setlocale(LC_TIME, 'C'); # this test relies on English output
      use Email::MIME;
      my ($j, $message_id) = @_;
      my ($mday, $mon, $year, $hour, $min, $sec) = split /[\/\s:]/, $j->{posted};
      my $date = strftime "%a, %d %b %Y %H:%M:%S GMT (GMT)", 
	$sec, $min, $hour, $mday, $mon - 1, $year - 1900;
      my $subject = "$j->{title} - Jobserve ref $j->{reference}";
      $subject =~ s#[\x80-\xFF]##g; # remove 8-bit chars from Subject - KISS
      my $html_body = <<EOF;
<h1>$j->{type}: $j->{title}</h1>
<p>
$j->{description}
</p>
<p>
Location: $j->{location}<br>
Salary/Rate: $j->{rate}<br>
$j->{recruitertype}: $j->{recruiter}<br>
@{[ 
$j->{recruiterlink} && "Recruiter website: <a href=\"$j->{recruiterlink}\">$j->{recruiterlink}</a><br>"
]}Contact: $j->{contact}<br>
Telephone: $j->{telephone}<br>
E-Mail: $j->{email}<br>
Reference: $j->{reference}<br>
Posted Date: $j->{posted}<br>
Job listing: <a href="$j->{joblink}">$j->{joblink}</a><br>
</p>
EOF
      my $e = Email::MIME->create(
	header => [
	  To => 'madeup@example.com',
	  From => ($j->{email} || 'madeup@example.com'),
	  Subject => $subject,
	  'Message-ID' => $message_id,
	  Date => $date,
	],
	attributes => {
	  content_type => 'text/html',
	  charset      => 'utf-8',
	  encoding     => 'quoted-printable',
	},
	body_str => $html_body,
      );
      $e->as_string;
    },
    $CONFIG{MESSAGESIZE}, # message size either padded or truncated to this
);
ok($mailbox, 'new worked');

my $tmpfh = File::Temp->new;
$mailbox->uidl_list($tmpfh);
$tmpfh->seek(0, Fcntl::SEEK_SET);
my $list = join '', <$tmpfh>;
my $list_ref = <<EOF;
1 $CONFIG{msgid1}
2 $CONFIG{msgid2}
3 $CONFIG{msgid3}
.
EOF
$list_ref =~ s#\n#\015\012#g;
ok(
  (
   $list eq $list_ref
   and $mailbox->messages == 3
   and $mailbox->octets == 3 * $CONFIG{MESSAGESIZE}
  ),
  'uidl_list'
);

ok($mailbox->uidl(2) eq $CONFIG{msgid2}, 'uidl');

$mailbox->delete(2);
$tmpfh = File::Temp->new;
$mailbox->uidl_list($tmpfh);
$tmpfh->seek(0, Fcntl::SEEK_SET);
$list = join '', <$tmpfh>;
$list_ref = <<EOF;
1 $CONFIG{msgid1}
3 $CONFIG{msgid3}
.
EOF
$list_ref =~ s#\n#\015\012#g;
ok(
  (
    $list eq $list_ref
    and $mailbox->messages == 2
    and $mailbox->octets == 2 * $CONFIG{MESSAGESIZE}
  ),
  'delete'
);

$tmpfh = File::Temp->new;
$mailbox->top(1, $tmpfh, $CONFIG{messagelines});
$tmpfh->seek(0, Fcntl::SEEK_SET);
my $top = join '', <$tmpfh>;
my ($topref_head, $topref_body) = split /\n{2}/, $CONFIG{messagetext};
$topref_body = join "\n",
  (split /\n/, $topref_body)[0..$CONFIG{messagelines}-1];
my $top_ref = join("\n\n", $topref_head, $topref_body) . "\n.\n";
$top_ref =~ s#\n#\015\012#g;
#warn "t: ($top)\ntr: ($top_ref)\n";
is($top, $top_ref, 'top');

$tmpfh = File::Temp->new;
$mailbox->retrieve(1, $tmpfh);
$tmpfh->seek(0, Fcntl::SEEK_SET);
my $retrieve = join '', <$tmpfh>;
#warn "rl: ".length($retrieve)."\n";
#warn "r: ($retrieve)\n";
my $retrieve_ref = $CONFIG{messagetext};
$retrieve_ref .= (' ' x ($CONFIG{MESSAGESIZE} - length($retrieve_ref) - 2))
  . "\n";
$retrieve_ref =~ s#\n#\015\012#g;
#warn "rrl: ".length($retrieve_ref)."\n";
#warn "rr: ($retrieve_ref)\n";
is($retrieve, $retrieve_ref, 'retr');
ok($mailbox->octets(2) == $CONFIG{MESSAGESIZE}, 'retr octets');

ok(!$mailbox->is_valid(2) and $mailbox->is_valid(3), 'is_valid');

$mailbox->reset;
ok($mailbox->is_valid(2) and $mailbox->is_valid(3), 'reset');
$mailbox->delete(2);

ok(($mailbox->is_deleted(2) and !$mailbox->is_deleted(3)), 'is_deleted');

done_testing;
