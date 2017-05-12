#!/bin/sh

# Change the --value parameters below to the dsn, user, and password of the 
# indexer database.  Then run this script to configure 
# Helios::App::MP3IndexerService in the Helios collective database.


helios_config_set --service="Helios::App::MP3IndexerService" --hostname="*" --param="mp3db_dsn" --value=""
helios_config_set --service="Helios::App::MP3IndexerService" --hostname="*" --param="mp3db_user" --value=""
helios_config_set --service="Helios::App::MP3IndexerService" --hostname="*" --param="mp3db_pass" --value=""

