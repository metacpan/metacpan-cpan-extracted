#!./bin/jspl

require('SDL', 'SDL');
require('SDL.App', 'SDL::App');
require('SDL.Rect', 'SDL::Rect');
require('SDL.Color', 'SDL::Color');
require('SDL.Event', 'SDL::Event');
require('SDL.Timer', 'SDL::Timer');

var app = new SDL.App(
    '-title', 'Foo bar',
    '-width', 640,
    '-height', 480,
    '-depth', 32
);

var rect = new SDL.Rect('-width', 10, '-height', 10, '-x', 320);
var colr = new SDL.Color('-r', 0, '-g', 0, '-b', 255);

function rand(n) {
    return Math.floor(Math.random() * n);
}

var y = 0;

function step() {
    if(y > 470) {
	y = 0;

	rect.x(rand(640));

	colr.r(rand(256));
	colr.g(rand(256));
	colr.b(rand(256));
    }

    rect.y(y);
    app.fill(rect, colr);
    app.update(rect);
    app.sync();

    y += 10;
};

var event = new SDL.Event();
var done = false;

while(!done) {
    step();
    if(event.poll()) {
	if(event.type() == SDL.SDL_QUIT()) {
	    Sys.say('quitting');
	    done = true;
	}
    }
}
