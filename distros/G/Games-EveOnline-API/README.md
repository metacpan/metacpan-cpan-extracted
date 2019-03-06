# NAME

Games::EveOnline::API - A simple Perl wrapper around the EveOnline XML API. (DEPRECATED)

# SYNOPSIS

    use Games::EveOnline::API;
    my $eapi = Games::EveOnline::API->new();
    
    my $skill_groups = $eapi->skill_tree();
    my $ref_types    = $eapi->ref_types();
    my $systems      = $eapi->sovereignty();
    
    # The rest of the methods require authentication.
    my $eapi = Games::EveOnline::API->new( user_id => '..', api_key => '..' );
    
    my $characters  = $eapi->characters();
    my $sheet       = $eapi->character_sheet( character_id => $character_id );
    my $in_training = $eapi->skill_in_training( character_id => $character_id );

# DEPRECATED

This module is no longer being maintained as the XML API is no more.

# DESCRIPTION

This module provides a Perl wrapper around the Eve-Online API, version 2.
The need for the wrapper arrises for two reasons.  First, the XML that
is provided by the API is overly complex, at least for my taste.  So, other
than just returning you a perl data representation of the XML, it also
simplifies the results.

Only a couple of the methods provided by this module can be used straight
away.  The rest require that you get a user\_id (keyID) and api\_key (vCode).

# A NOTE ON CACHING

Most of these methods return a 'cached\_until' value.  I've no clue if this
is CCP telling you how long you should cache the information before you
should request it again, or if this is the point at which CCP will refresh
their cache of this information.

Either way, it is good etiquet to follow the cacheing guidelines of a
provider.  If you over-use the API I'm sure you'll eventually get blocked.

# ARGUMENTS

## user\_id

An Eve Online API user ID (also known as a keyID).

## api\_key

The key, as provided Eve Online, to access the API (also known
as a vCode).

## character\_id

Set the default `character_id`.  Any methods that require
a characte ID, and are not given one, will use this one.

## api\_url

The URL that will be used to access the Eve Online API.
Defaults to [https://api.eveonline.com](https://api.eveonline.com).  Normally you
won't want to change this.

## ua

The underlying [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) object.  Default to a new one
with no special arguments.  Override this if you want to, for
example, enable keepalive or an HTTP proxy.

# ANONYMOUS METHODS

These methods may be called anonymously, without authentication.

## skill\_tree

    my $skill_groups = $eapi->skill_tree();

Returns a complex data structure containing the entire skill tree.
The data structure is:

    {
        cached_until => $date_time,
        $group_id    => {
            name   => $group_name,
            skills => {
                $skill_id => {
                    name                => $skill_name,
                    description         => $skill_description,
                    rank                => $skill_rank,
                    primary_attribute   => $skill_primary_attribute,
                    secondary_attribute => $skill_secondary_attribute,
                    bonuses             => {
                        $bonus_name => $bonus_value,
                    },
                    required_skills => {
                        $skill_id => $skill_level,
                    },
                }
            }
        }
    }

## ref\_types

    my $ref_types = $eapi->ref_types();

Returns a simple hash structure containing definitions of the
various financial transaction types.  This is useful when pulling
wallet information. The key of the hash is the ref type's ID, and
the value of the title of the ref type.

## sovereignty

    my $systems = $eapi->sovereignty();

Returns a hashref where each key is the system ID, and the
value is a hashref with the keys:

    name
    faction_id
    sovereignty_level
    constellation_sovereignty
    alliance_id

# RESTRICTED METHODS

These methods require authentication to use, so you must have set
the ["user\_id"](#user_id) and ["api\_key"](#api_key) arguments to use them.

## characters

    my $characters = $eapi->characters();

Returns a hashref where key is the character ID and the
value is a hashref with a couple bits about the character.
Here's a sample:

    {
        '1972081734' => {
            'corporation_name' => 'Bellator Apparatus',
            'corporation_id'   => '1044143901',
            'name'             => 'Ardent Dawn'
        }
    }

## character\_sheet

    my $sheet = $eapi->character_sheet( character_id => $character_id );

For the given character ID a hashref is returned with
the all the information about the character.  Here's
a sample:

    {
        'name'             => 'Ardent Dawn',
        'balance'          => '99010910.10',
        'race'             => 'Amarr',
        'blood_line'       => 'Amarr',
        'corporation_name' => 'Bellator Apparatus',
        'corporation_id'   => '1044143901',
    
        'skills' => {
            '3455' => {
                'level'        => '2',
                'skill_points' => '1415'
            },
    
            # Removed the rest of the skills for readability.
        },
    
        'attribute_enhancers' => {
            'memory' => {
                'value' => '3',
                'name'  => 'Memory Augmentation - Basic'
            },
    
            # Removed the rest of the enhancers for readability.
        },
    
        'attributes' => {
            'memory'       => '7',
            'intelligence' => '7',
            'perception'   => '4',
            'charisma'     => '4',
            'willpower'    => '17'
        }
    }

## skill\_in\_training

    my $in_training = $eapi->skill_in_training( character_id => $character_id );

Returns a hashref with the following structure:

    {
        'current_tq_time' => {
            'content' => '2008-05-10 04:06:35',
            'offset'  => '0'
        },
        'end_time'   => '2008-05-10 19:23:18',
        'start_sp'   => '139147',
        'to_level'   => '5',
        'start_time' => '2008-05-07 16:15:05',
        'skill_id'   => '3436',
        'end_sp'     => '256000'
    }

## api\_key\_info

    my $api_info = $eapi->api_key_info();

Returns a hashref with the following structure:

    {
        'cached_until' => '2014-06-26 16:57:40',
        'type'         => 'Account',
        'access_mask'  => '268435455',
        'characters'   => {
            '12345678' => {
                'faction_id'       => '0',
                'character_name'   => 'Char Name',
                'corporation_name' => 'School of Applied Knowledge',
                'faction_name'     => '',
                'alliance_id'      => '0',
                'corporation_id'   => '1000044',
                'alliance_name'    => ''
            },
            '87654321' => {
                'faction_id'       => '0',
                'character_name'   => 'Char Name2',
                'corporation_name' => 'Corp Name',
                'faction_name'     => '',
                'alliance_id'      => '1234567890',
                'corporation_id'   => '987654321',
                'alliance_name'    => 'Alliance Name'
            }
        },
        'expires' => ''
    }

## account\_status

    my $account_status = $eapi->account_status();

Returns a hashref with the following structure:

    {
        'cachedUntil'   => '2014-06-26 17:17:12',
        'logon_minutes' => '79114',
        'logon_count'   => '940',
        'create_date'   => '2011-06-22 11:44:37',
        'paid_until'    => '2014-08-26 16:37:43'
    }

## character\_info

    my $character_info = $eapi->character_info( character_id => $character_id );

Returns a hashref with the following structure:

    {
        'character_name'     => 'Char Name',
        'alliance_id'        => '1234567890',
        'corporation_id'     => '987654321',
        'corporation'        => 'Corp Name',
        'alliance'           => 'Alliance Name',
        'race'               => 'Caldari',
        'bloodline'          => 'Achura',
        'skill_points'       => '40955856',
        'employment_history' => {
            '23046655' => {
                'corporation_id' => '123456789',
                'start_date'     => '2013-02-03 13:39:00',
                'record_id'      => '23046655'
            },
            '29131760' => {
                'corporation_id' => '987654321',
                'start_date'     => '2013-11-04 16:40:00',
                'record_id'      => '29131760'
            },
        },
        'ship_type_id'        => '670',
        'account_balance'     => '38131.68',
        'cached_until'        => '2014-06-26 17:18:29',
        'last_known_location' => 'Jita',
        'character_id'        => '12345678',
        'alliance_date'       => '2012-08-05 00:12:00',
        'corporation_date'    => '2012-09-11 20:32:00',
        'ship_type_name'      => 'Capsule',
        'security_status'     => '1.3534973114985',
        'ship_name'           => 'Char Name Capsule'
    }

## asset\_list

    my $asset_list = $eapi->asset_list( character_id => $character_id );

Returns a hashref with the following structure:

    {
        '1014951232473' => {
            'contents' => {
                '1014957890964' => {
                    'type_id'      => '2454',
                    'quantity'     => '1',
                    'flag'         => '87',
                    'raw_quantity' => '-1',
                    'singleton'    => '1',
                    'item_id'      => '1014957890964'
                }
            },
            'quantity'     => '1',
            'flag'         => '4',
            'location_id'  => '60014680',
            'singleton'    => '1',
            'item_id'      => '1014951232473',
            'type_id'      => '32880',
            'raw_quantity' => '-1'
        },
        '1014951385057' => {
            'type_id'      => '1178',
            'quantity'     => '1',
            'flag'         => '4',
            'raw_quantity' => '-2',
            'location_id'  => '60015001',
            'singleton'    => '1',
            'item_id'      => '1014951385057'
        }
    }

## contact\_list

    my $contact_list = $eapi->contact_list( character_id  => $character_id );

Returns a hashref with the following structure:

    {
        'contact_list' => {
            '962693552' => {
                'standing'        => '10',
                'contact_name'    => 'Char Name',
                'contact_id'      => '962693552',
                'in_watchlist'    => undef,
                'contact_type_id' => '1384'
            },
            '3019494' => {
                'standing'        => '0',
                'contact_name'    => 'Char Name 3',
                'contact_id'      => '3019494',
                'in_watchlist'    => undef,
                'contact_type_id' => '1375'
            },
            '1879838281' => {
                'standing'        => '10',
                'contact_name'    => 'Char Name 2',
                'contact_id'      => '1879838281',
                'in_watchlist'    => undef,
                'contact_type_id' => '1378'
            }
        }
    }

## wallet\_transactions

    my $wallet_transactions = $eapi->wallet_transactions(
        character_id => $character_id,
        row_count    => $row_count,        # optional, default is 2560
        account_key  => $account_key,      # optional, default is 1000
        from_id      => $args{from_id},    # optional, need for offset
    );

Returns a hashref with the following structure:

    {
        '3499165305' => {
            'type_name'             => 'Mining Frigate',
            'quantity'              => '1',
            'client_id'             => '90646537',
            'transaction_date_time' => '2014-06-28 12:23:41',
            'station_id'            => '60015001',
            'transaction_id'        => '3499165305',
            'transaction_for'       => 'personal',
            'type_id'               => '32918',
            'station_name'     => 'Akiainavas III - School of Applied Knowledge',
            'client_name'      => 'Zeta Zhang',
            'price'            => '1201.02',
            'transaction_type' => 'sell'
        },
        '3482136396' => {
            'type_name'             => 'Mining Barge',
            'quantity'              => '1',
            'client_id'             => '1000167',
            'transaction_date_time' => '2014-06-15 20:15:26',
            'station_id'            => '60014680',
            'transaction_id'        => '3482136396',
            'transaction_for'       => 'personal',
            'type_id'               => '17940',
            'station_name'          => 'Autama V - Moon 9 - State War Academy',
            'client_name'           => 'State War Academy',
            'price'                 => '500000.00',
            'transaction_type'      => 'buy'
        }
    }

## wallet\_journal

    my $wallet_journal = $eapi->wallet_journal(
        character_id => $character_id,
        row_count    => $row_count,        # optional, default is 2560
        account_key  => $account_key,      # optional, default is 1000
        from_id      => $args{from_id},    # optional, need for offset
    );

Returns a hashref with the following structure:

    {
        '9729070529' => {
            'owner_name2'     => 'Milolika Muvila',
            'arg_id1'         => '0',
            'date'            => '2014-07-08 19:02:53',
            'reason'          => '',
            'tax_receiver_id' => '',
            'owner_name1'     => 'Cyno Chain',
            'amount'          => '814900000.00',
            'owner_id1'       => '93496706',
            'tax_amount'      => '',
            'balance'         => '826371087.94',
            'arg_name1'       => '3513456219',
            'ref_id'          => '9729070529',
            'ref_type_id'     => '2',
            'owner_id2'       => '94701913'
        },
        '9729071394' => {
            'owner_name2'     => '',
            'arg_id1'         => '0',
            'date'            => '2014-07-08 19:03:04',
            'reason'          => '',
            'tax_receiver_id' => '',
            'owner_name1'     => 'Milolika Muvila',
            'amount'          => '-28369982.50',
            'owner_id1'       => '94701913',
            'tax_amount'      => '',
            'balance'         => '785777605.44',
            'arg_name1'       => '',
            'ref_id'          => '9729071394',
            'ref_type_id'     => '42',
            'owner_id2'       => '0'
        }
    }

## mail\_messages

    my $mail_messages = $eapi->mail_messages( character_id => $character_id );

Returns a hashref with the following structure:

    {
        '331477595' => {
            'to_list_id'             => '145156607',
            'message_id'             => '331477595',
            'to_character_ids'       => '',
            'sender_id'              => '91669871',
            'sent_date'              => '2013-10-08 06:30:00',
            'to_corp_or_alliance_id' => '',
            'title' =>
                "\x{420}\x{430}\x{441}\x{43f}\x{440}\x{43e}\x{434}\x{430}\x{436}\x{430}",
            'sender_name' => 'Valerii Ostudnev'
        },
        '336393982' => {
            'to_list_id'             => '',
            'message_id'             => '336393982',
            'to_character_ids'       => '1203082547',
            'sender_id'              => '90922771',
            'sent_date'              => '2014-03-02 13:30:00',
            'to_corp_or_alliance_id' => '',
            'title'                  => 'TSG -&gt; Z-H',
            'sender_name'            => 'Chips Merkaba'
        },
        'cached_until' => '2014-07-10 18:33:59'
    }

## mail\_bodies

    my $mail_bodies = $eapi->mail_bodies( character_id  => $character_id, ids => $ids );

Returns a hashref with the following structure:

    {
        'cached_until'        => '2024-07-07 18:13:16',
        'missing_message_ids' => '331477591',
        '331477595' =>
            "<font size=\"12\" color=\"#bfffffff\"></font><font size=\"12\" color=\"#fff7931e\"><a href=\"contract:30004977//73497683\">[Multiple Items]</a></font>"
    }

## mail\_lists

    my $mail_lists = $eapi->mail_lists( character_id  => $character_id );

Returns a hashref with the following structure:

    {
        'cached_until' => '2014-07-11 00:06:57',
        '145156367'    => 'RAISA Shield Fits'
    }

## character\_name

    my $character_name = $eapi->character_name( ids => '90922771,94701913' );

Returns a hashref with the following structure:

    {
        '94701913'     => 'Milolika Muvila',
        'cached_until' => '2014-08-10 20:59:55',
        '90922771'     => 'Chips Merkaba'
    }

## character\_ids

    my $character_ids = $eapi->character_ids( names => 'Milolika Muvila,Chips Merkaba' );

Returns a hashref with the following structure:

    {
        '94701913'     => 'Milolika Muvila',
        'cached_until' => '2014-08-10 20:59:55',
        '90922771'     => 'Chips Merkaba'
    }

## station\_list

    my $station_list = $eapi->station_list();

Returns a hashref with the following structure:

    {
        '61000051' => {
            'station_type_id'  => '21644',
            'corporation_name' => 'Nulli Secunda Holding',
            'corporation_id'   => '1463841432',
            'station_name'     => 'DB1R-4 VIII - We brought the Trash Out',
            'solar_system_id'  => '30004470',
            'station_id'       => '61000051'
        },
        '61000438' => {
            'station_type_id'  => '21646',
            'corporation_name' => 'Greater Western Co-Prosperity Sphere Exec',
            'corporation_id'   => '98237912',
            'station_name'     => 'F-D49D III - Error - Clever name not found',
            'solar_system_id'  => '30000279',
            'station_id'       => '61000438'
        }
    }

## corporation\_sheet

    my $station_list = $eapi->corporation_sheet();

Returns a hashref with the following structure:

    {
        'shares'         => '1000',
        'faction_id'     => '0',
        'cached_until'   => '2014-08-24 22:18:02',
        'member_count'   => '43',
        'alliance_id'    => '0',
        'corporation_id' => '1043735888',
        'description' =>
            "\x{418}\x{441}\x{441}\x{43b}\x{435}\x{434}\x{43e}\x{432}\x{430}\x{43d}\x{438}\x{44f} \x{438} \x{440}\x{430}\x{437}\x{440}\x{430}\x{431}\x{43e}\x{442}\x{43a}\x{438}",
        'station_id' => '60004861',
        'ceo_name'   => 'Krasotulya',
        'logo'       => {
            'color3'     => '674',
            'color1'     => '677',
            'shape3'     => '415',
            'shape2'     => '480',
            'graphic_id' => '0',
            'shape1'     => '437',
            'color2'     => '676'
        },
        'tax_rate'         => '5',
        'corporation_name' => 'Zaporozhye Sich',
        'ceo_id'           => '423270919',
        'url'              => 'http://',
        'station_name' => 'Lasleinur V - Moon 11 - Republic Fleet Assembly Plant'
    }

# SEE ALSO

- [WebService::EveOnline](https://metacpan.org/pod/WebService::EveOnline)

# AUTHORS

    Aran Clary Deltac <bluefeet@gmail.com>
    Andrey Chips Kuzmin <chipsoid@cpan.org>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
