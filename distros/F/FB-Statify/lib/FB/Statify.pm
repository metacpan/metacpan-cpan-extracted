#!usr/bin/perl
package FB::Statify;
use WWW::Mechanize;
use WWW::Mechanize::Firefox;
use List::MoreUtils qw(uniq);
=head1 NAME

B<Statify> - FaceBook profile analysis without FaceBook's API

=head1 SYNOPSIS

	C<< my $statify= new FB::Statify('username@domain.com',"password",0); >>

=head1 DESCRIPTION

This module attempts to give the ability to conduct profile analysis over a targeted graph of friends, and , if combined with statistical and psychological tools, can possibly yield great and unexpected results.
It was made in order bypass the use of FaceBook's Graph API, since it requires user interaction and user permission. 

=head2 Methods

=over 12

=item C<new>

Returns a new FB::Statify object

=over 12

=item C<_username>

The FaceBook username of the scanner

=item C<_password>

The password for the username

=item C<_loggedIn>

Boolean flag. True if already logged in in Firefox, False if not.

=back

=item C<genderSplit>

Takes an array of friends (assuming they exist) and checks how many of them are male, female. If a gender is ambiguous or undefined, it is stored in the undefined variable.
C<< my @genders=$statify->genderSplit(\@friends); >>

=item C<getFriendsList>

Takes a username and returns an array of friends of this user
C<< my @friends=$statify->getFriendsList('targetUsername'); >>

=item C<getFriendsAmount>

Takes a username and returns the scalar amount of friends of this user
C<< my $friends=$statify->getFriendsAmount('targetUsername'); >>

=item C<getLikes>

Takes a username and returns the amount of likes on the user's photos as an array
C<< my @likes=$statify->getLikes('targetUsername'); >>

=item C<login>

Non functionnal subroutine, used only to automatize logging in for C<WWW::Mechanize::Firefox>

=back

=head1 LICENSE

Distributed according to GNU GPL and CPAN Terms and Conditions.
You may re-use and publish the code, but you have to mention the original AUTHOR and CPAN repo.
You may NOT sell this module.

=head1 AUTHOR

ArtificialBreeze - L<http://github.com/ArtificialBreeze> -L<https://metacpan.org/author/ArtificialBreeze>

=head1 SEE ALSO

L<perlpod>, L<perlpodspec>

=cut
sub new
{
	my $class =shift;
	my $self=
	{
		_username => shift,
		_password => shift,
		_loggedIn => shift,
	};
	bless $self,$class;
	return $self;
}
sub genderSplit
{
	my ($self,@friends)=@_;
	$mech = WWW::Mechanize->new();
	$mech->agent_alias( 'Windows IE 6' );
	$mech->get("https://www.facebook.com/");
	$mech->form_id("login_form");
	$mech->field("email",$self->{_username});
	$mech->field("pass",$self->{_password});
	$mech->click();
	our $females=0;
	our $males=0;
	our $undef=0;
	foreach (@friends)
	{	
		$mech->get("https://www.facebook.com/".$_."/about?section=contact-info");
		my $content=$mech->content();
		my $_gender='Gender</span></div><div class="_4bl7 _pt5"><div class="clearfix"><div><span class="_50f4">';
		my $gender_='</span>';
		$content =~ /$_gender(.*?)$gender_/;
		my $gender= $1;
		if ($gender eq 'Female')
		{
			$females++;
		}
		elsif($gender eq 'Male')
		{
			$males++;
		}
		else 
		{
			$undef++;
		}
	}
	return ($females,$males,$undef);
}
sub getFriendsList{
my ($self,$user)=@_;
if (!$self->{_loggedIn})
{
	$self->login();
}
my $mech = WWW::Mechanize::Firefox->new(tab => 'current');
my $url='https://www.facebook.com/'.$user.'/friends';
my (@friends);
$mech->get($url);
my $friendsnumber=getFriendsAmount($user);
my $count = $friendsnumber==0 ? 400/15 : $friendsnumber/15;
while($count>0)
{
sleep 1;
my ($window,$type) = $mech->eval('window');
$window->scrollByLines(180);
$count--;
}
my $x = $mech->content();
  my $_name='extragetparams=%7B%22hc_location%22%3A%22friends_tab%22%7D">';
  my $name_='</a></div>';
  my @friends=($x =~ /$_name(.*?)$name_/g);
  for (my $i=0;$i<scalar(@friends);$i++)
  {
	if ($friends[$i] =~ /</)
	{
		delete $friends[$i];
	}
	#Comment the following line to obtain the first and last name
	$friends[$i]=~ s/ .*//;
	$friends[$i]=lc $friends[$i];
  }
	return uniq(@friends);
	}
sub getFriendsAmount
{
my ($self,$user)=@_;
if (!$self->{_loggedIn})
{
	$self->login();
}
my $mech = WWW::Mechanize::Firefox->new(tab => 'current');
my $url='https://www.facebook.com/'.$user.'/friends';
my (@friends);
$mech->get('http://www.facebook.com/'.$user);
my $htmlfriends = $mech->content();
my $_friends='friends_mutual">'; 
my $friends_='</a> <a class="uiLinkSubtle"';
my $friendsnumber= ($htmlfriends =~ /$_friends(.*?)$friends_/) ? $1 : 0;
	return $friendsnumber;
}
sub getLikes{
my ($self,$user)=@_;
if (!$self->{_loggedIn})
{
	$self->login();
}
my $mech = WWW::Mechanize::Firefox->new(tab => 'current');
my $url='https://www.facebook.com/'.$user.'/photos';
my (@likes);
$mech->get($url);
my ($window,$type) = $mech->eval('window');
foreach (0..20)
{
sleep 1;
$window->scrollByPages(1);
}
my $content = $mech->content();
my $_like='<a class="_5gly _5glz" role="button" aria-label="';
my $like_=' like';
	@likes=($content =~ /$_like(.*?)$like_/g);
	for(my $i=0;$i<scalar(@likes);$i++)
	{
		if ($likes[$i] =~ /[a-zA-Z]/ || $likes[$i] =~ / / || $likes[$i] =~ /\n/ )
		{
			delete $likes[$i];
		}
	}
	return @likes;
}
sub login{
my $self=$_[0];
my $mech = WWW::Mechanize::Firefox->new(tab => 'current');
$mech->get('https://www.facebook.com/login.php?login_attempt=1');
$mech->submit_form(
   with_fields=>
   {
      email => $self->{_username},
      pass => $self->{_password},
   }
);
sleep 5;
}
1;