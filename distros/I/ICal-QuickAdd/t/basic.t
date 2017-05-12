use Test::More 'no_plan';
require DateTime;
use strict;

use ICal::QuickAdd;

{
    my @good_files = ('crlf.ics', 'evolution.ics');

    for my $f (@good_files) {
       ok(ICal::QuickAdd::_is_ical_file("t/".$f) , "$f is good ical file" );
    }

    ok((! ICal::QuickAdd::_is_ical_file('t/bad.ics')), "found bad ical file" );
}

{
    my $iqa = ICal::QuickAdd->new('Mar 31 1976 at noon. Lunch with Bob ');
    is($iqa->get_msg, 'Lunch with Bob', "msg is right... white space is trimmed.");
    my $dt = $iqa->get_dt;
    is($dt->ymd,   '1976-03-31', "DateTime date is correct");
    is($dt->hour,  '12', "DateTime hour is correct");
    is($dt->minute,'0', "DateTime minute is correct");

}

{
    use File::Copy;
    # We  seem to need this
    chmod 0755, 't';
    copy('t/evolution.ics', 't/evo_injectee.ics') || die "couldn't copy: $!";

    my $iqa = ICal::QuickAdd->new('Mar 31 1976 at noon. Party with Bob ');
    $iqa->inject_into_ics('t/evo_injectee.ics');

    use Text::vFile::asData;
    open my $fh, "t/evo_injectee.ics" or die "couldn't open ics: $!";
    eval { my $data = Text::vFile::asData->new->parse( $fh ) };
    is ($@, '', "after injection, the file is still parseable.. that's a good sign.");

    use File::Slurp;
    use Test::LongString;
    my $new_file = read_file('t/evo_injectee.ics');
    like_string($new_file, qr/Party/, "reality check that contents of new file contain the new event");

}

{
    my $iqa = ICal::QuickAdd->new('Mar 31 1976. Lunch with Bob ');
    # For now, we ignore that the time is wrong, which is mostly
    # a bug in DateTime::Format::Natural
    like($iqa->parsed_string,
       qr/Event: Lunch with Bob on Mar 31, 1976/,
       "dt_and_summary_to_desc returns expected result"); 

}

{
    my $iqa = ICal::QuickAdd->new('Mar 31 1976 at 12:34. Lunch with Bob ');
    is($iqa->parsed_string,
       "Event: Lunch with Bob on Mar 31, 1976 at 12:34",
       "dt_and_summary_to_desc returns expected result with 12:34 time"); 

}

{
    my $iqa = ICal::QuickAdd->new('Mar 31 1976 at 12:34. Lunch with Bob ');

    my $email_simple_obj = $iqa->as_ical_email( To => 'a@b.com', From => 'from@from.com' ); 
    like($email_simple_obj->as_string, qr/To/, "resulting email contains To");
    like($email_simple_obj->as_string, qr/From/, "resulting email contains From");
    like($email_simple_obj->as_string, qr/Date/, "resulting email contains Date");
    
}

# vim: nospell


