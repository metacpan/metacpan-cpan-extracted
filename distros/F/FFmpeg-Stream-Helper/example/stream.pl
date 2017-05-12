use FFmpeg::Stream::Helper;
use Mojolicious::Lite;
use Mojo::IOLoop::ReadWriteFork;

get '/' => sub {
	my $c = shift;
	$c->render(template=>'root');
};

get '/video.webm' => sub {
	my $self = shift->render_later;

	#$self->res->headers->content_length('*');
	
	my $fork = Mojo::IOLoop::ReadWriteFork->new;

    my $fsh=FFmpeg::Stream::Helper->new;
	
	my $command=$fsh->command('/arc/video/movies/Fear and Loathing in Las Vegas.avi');

	$self->stash(fork => $fork);

	my $tx = $self->tx;
	
	$self->on(finish => sub {
		my $self = shift;
		my $fork = $self->stash('fork') or return;
		app->log->debug("Ending ffmpeg process");
		$fork->kill;
		undef $tx;
			  });

	$fork->on(read => sub {
		my($fork, $buffer) = @_;
		$self->write_chunk($buffer);
			  });

	warn ($command);
	
	$fork->start(program => $command);
};

app->start;

__DATA__

@@ root.html.ep

<!DOCTYPE html> 
<html> 
<head>
<link href="//vjs.zencdn.net/5.8/video-js.min.css" rel="stylesheet">
<script src="//vjs.zencdn.net/5.8/video.min.js"></script>
<META HTTP-EQUIV="CACHE-CONTROL" CONTENT="NO-CACHE">
<META HTTP-EQUIV="PRAGMA" CONTENT="NO-CACHE">
</head>
<body> 

<div style="text-align:center"> 
  <video id="video0" autoplay class="video-js vjs-default-skin" controls preload="none" >
    <source src="video.webm" type="video/webm">
    Your browser does not support HTML5 video.
  </video>
</div> 

</body> 
</html>

