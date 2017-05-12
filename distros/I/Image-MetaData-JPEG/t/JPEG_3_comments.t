use Test::More tests => 25;
BEGIN { require 't/test_setup.pl'; }

my $tphoto = 't/test_photo.jpg';
my $tdata  = 't/test_photo.desc';
my $limit  = 2**16 - 3;
my $com2   = 'x' x $limit;
my $com3   = 'x' x ($limit + 1);
my $com4   = "Regular comment";
my ($image, $newim, @list, $num, @savelist, @sl, $buffer);

my $reduce = sub {
    @{$_[0]} = map {(length $_ > $limit) ? (substr($_,0,$limit),
					    substr($_,$limit)) :$_} @{$_[0]};};

#===============================
diag "Testing comment routines";
#===============================

BEGIN { use_ok ($::pkgname) or exit; }

#########################
$image = newimage($tphoto);
is( $image->get_number_of_comments(), $num=1, "Get number of comments" );

#########################
$image->add_comment($com2);
is( $image->get_number_of_comments(), ++$num, "Two comments now" );

#########################
@list = $image->get_comments();
is( $list[1], $com2, "Rereading second comment" );

#########################
$image->add_comment($com3);
is( $image->get_number_of_comments(), ($num+=2), "Comment too long, broken" );

#########################
$image->set_comment(2, $com4);
@list = $image->get_comments();
is( $list[2], $com4, "Setting an existing comment" );

#########################
isnt( $list[2], $com3, "Just to see we really read" );

#########################
$image->set_comment(0, $com3);
is( $image->get_number_of_comments(), ++$num, "Set with long comment" );

#########################
@savelist = $image->get_comments();
is( $savelist[2], $com2, "Second comment now third" );

#########################
$image->set_comment(2, undef);
is( $image->get_number_of_comments(), --$num, "Erase comment with undef set" );

#########################
$image->remove_comment(1);
is( $image->get_number_of_comments(), --$num, "Remove one comment" );

#########################
open DUP_ERR, ">&STDERR"; close STDERR;
$image->remove_comment(-1);
open STDERR, ">&DUP_ERR"; close DUP_ERR;
is( $image->get_number_of_comments(), $num, "Remove out-of-bound" );

#########################
open DUP_ERR, ">&STDERR"; close STDERR;
$image->remove_comment($num);
open STDERR, ">&DUP_ERR"; close DUP_ERR;
is( $image->get_number_of_comments(), $num, "Remove out-of-bound (2)" );

#########################
$image->remove_all_comments();
is( $image->get_number_of_comments(), 0, "Erase all comments" );

#########################
@list = $image->get_comments();
is_deeply( \ @list, [], "No comments as a list" );

#########################
$image->add_comment($_) for @savelist; $num = @savelist;
is( $image->get_number_of_comments(), $num, "Restoring comments" );

#########################
@sl = @savelist;
@sl = ( $sl[0]."-".$sl[2]."-".$sl[4], $sl[1], $sl[3]);
&$reduce(\@sl) for (1..((length $sl[0]) / $limit));
$image->join_comments("-", 0, 2, 4);
@list = $image->get_comments();
is_deeply( \@list, \@sl, "Complex joining" );

#########################
@sl = (join "***", @sl);
&$reduce(\@sl) for (1..((length $sl[0]) / $limit));
$image->join_comments("***");
@list = $image->get_comments();
is_deeply( \@list, \@sl, "Total joining" );

#########################
eval { $image->join_comments("-", 0, 2, -4) };
isnt( $@, '', "Negative index in join_comments catched" );

#########################
eval { $image->join_comments("-", 0, 114, 2) };
isnt( $@, '', "Out-of-bound index in join_comments catched" );

#########################
eval { $image->join_comments("-", undef, 0) };
isnt( $@, '', "Undefined index in join_comments catched" );

#########################
eval { $image->join_comments("-", 'invalid', 2, 4) };
isnt( $@, '', "Invalid index in join_comments catched" );

#########################
$image->remove_all_comments();
$image->add_comment($_) for @savelist; $num = @savelist;
$image->save(\ ($buffer = ""));
$newim = newimage(\ $buffer);
@list = $newim->get_comments();
is_deeply( \@list, \@savelist, "Save and re-read" );

#########################
$image->remove_all_comments();
$image->add_comment("Dummy");
$image->set_comment(0, "");
$image->save(\ ($buffer = ""));
$newim = newimage(\ $buffer);
ok( $newim, "Saving a picture with a null comment" );

#########################
@list = $newim->get_comments();
is_deeply( \@list, [ "" ], "The comment is really null" );

### Local Variables: ***
### mode:perl ***
### End: ***
