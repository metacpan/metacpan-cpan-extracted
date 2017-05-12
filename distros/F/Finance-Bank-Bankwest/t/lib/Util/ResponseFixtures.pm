use MooseX::Declare;
role t::lib::Util::ResponseFixtures {

    use URI::file 4.21 (); # for correct query string handling
    use WWW::Mechanize ();

    method uri_for(Str $basename) {
        $basename .= '.html' if $basename !~ /\./;
        return URI::file->new_abs("t/fixtures/$basename")->as_string;
    }

    method response_for(Str $basename) {
        return WWW::Mechanize->new->get($self->uri_for($basename));
    }
}
