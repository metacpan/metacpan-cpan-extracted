package Grimlock;
{
  $Grimlock::VERSION = '0.11';
}

=head1 NAME

Grimlock - KING OF CMS

=head1 SYNOPSIS

ME GRIMLOCK SAY YOU MUST MAKE DATABASE

  dbicadmin --schema=Grimlock::Schema   --connect='["dbi:SQLite:grimlock.db", "", ""]' --deploy

OR FOR DATABASE THAT NO SUCK 

  dbicadmin --schema=Grimlock::Schema   --connect='["dbi:Pg:dbname=grimlock", "grimlock", "king!"]' --deploy

NOW START SERVER 

  starman --listen :5000 --workers 2 /path/to/grimlock_web.psgi --pid /tmp/grimlock.pid --error-log /path/to/error.log -D

=head1 STARMAN AND CUSTOM CONFIG

ME GRIMLOCK RECOMMEND SPECIFYING CONFIG VARS LIKE SO:

PUT THIS IN FILE AND SAVE

  name Grimlock::Web
  default_view HTML
  <Model::Database>
    <connect_info>
      dsn dbi:Pg:dbname=blog
      user grimlock
      password beryllium_baloney
      quote_names 1
    </connect_info>
  </Model::Database>
  <blog>
    title GRIMLOCK KING
  </blog>
  <Plugin::Session>
    dbic_class Database::Session
    expires 3600
    flash_to_stash 1
  </Plugin::Session>
  <Plugin::Authentication>
    default_realm members
    <realms>
      <members>
       <credential>
         class Password
         password_field password
         password_type self_check 
       </credential>
       <store>
         class DBIx::Class
         user_model Database::User
         role_relation roles
         role_field name
       </store>
      </members>
    </realms>
  </Plugin::Authentication>
  
THEN, START GRIMLOCK LIKE SO

  CATALYST_CONFIG=/path/to/config/you/just/made.conf starman --listen :5000 --workers 2 /path/to/grimlock_web.psgi --pid /tmp/grimlock.pid --error-log /path/to/error.log -D


IF NO EXPLODE, GRIMLOCK SAVE BLOG FOR YOU

=head1 STARMAN + NGINX

ME GRIMLOCK LIKE NGINX FOR WEB SERVER.  IT FAST AND EASY.

ADD THIS TO NGINX CONFIG FILE:

  server {
    listen       80;
    server_name  grimlock.me;
    
    #charset koi8-r;
    access_log  /var/log/nginx/access.log;
    error_log   /var/log/nginx/error.log;
    location / {
       proxy_set_header Host $http_host;
       proxy_set_header X-Forwarded-Host $host;
       proxy_set_header X-Real-IP $remote_addr;
       proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
       proxy_pass        http://localhost:5000/;
    }

    location /static {
      root /path/to/grimlock.me;
    }
  

NOW YOU MAKE SYMLINK TO GRIMLOCK STATIC ASSETS

  locate Grimlock/static
  ln -s path_from_above path_in_nginx_config

NOW RESTART NGINX, AND CMS SHOULD WORK.

=head1 DESCRIPTION

ME GRIMLOCK NO LIKE HAVING TO RUN APACHE TO USE BLOG LIKE MOVABLE TYPE.  ME GRIMLOCK ALSO HATE WORDPRESS, STUPID REMOTE SHELL WITH WEB BLOG FEATURE.

SO ME GRIMLOCK MAKE THIS BLOG SO I CAN WRITE ABOUT PETRO RABBITS, KICKING BUTT, AND MUNCHING METAL.

ME GRIMLOCK KING!

=head1 NOTES

GRIMLOACK AM ANXIOUS TO MAKE SOFTWARE FAST SO GRIMLOCK RELEASE FAST IN ITERATIVE DESIGN SPIRIT.  THIS CODE AM IN VERY EARLY ALPHA STAGE AND PROBABLY NO WORK ALL THE WAY.

IF YOU RUN INTO ISSUE, CRAM IT, GRIMLOCK NO LIKE RT TICKETS.

=head1 TODO

ME GRIMLOCK WRITE BAD ASS SOFTWARE BUT NO HAVE TIME TO WRITE EVERYTHING AT ONCE.  THIS BLOG NEED:

1. BETTER DESIGN.  DESIGN SUCK AND LOOK BAD.

2. SEARCH.  I GUESS USE SOMETHING LIKE LUCY FOR DEFAULT SEARCH, WHAT, ME LOOK LIKE GOOGLE TO YOU?

3. WORKER PROCESS THINGY.  ME WANT PROCESS THINGS IN GOOD SOFTWARE DESIGN METHODOLOGY SO ME NO MAKE WEB APP DO LOTS OF WORK.

4. ATTACHMENTS.  IMAGES OF SLUDGE GETTING BUTT KICKED BY DEVASTATOR MAKE GRIMLOCK LAUGH, ME WANT UPLOAD EVERYDAY.

5. REMOVE ::NEXT STUFF FROM VIEW::TT.  NEXT IS DUMB. ME NO LIKE.

=head1 LICENSE

ME GRIMLOCK WANT SHARE BEAUTIFUL SOFTWARE ME WRITE WITH WORLD.  ME GRIMLOCK SAY THIS SOFTWARE RELEASE UNDER ARTISTIC LICENSE.

SEE L<perlartistic>.

=head1 AUTHOR

ME, GRIMLOCK!

GRIMLOCK NO USE EMAIL, EMAIL BORING. EMAIL THIS GUY INSTEAD: L<mailto:dhoss@cpan.org>


=head1 SEE ALSO

L<http://www.imdb.com/title/tt0092106/>

=cut

1;
