#!./bin/jspl

require('SDL', 'SDL');
require('SDL.App', 'SDL::App');
require('SDL.Timer', 'SDL::Timer');
require('SDL.Rect', 'SDL::Rect');
require('SDL.Color', 'SDL::Color');
require('SDL.Event', 'SDL::Event');

function rand(n) {
    return Math.floor(Math.random() * n);
}

var app = new SDL.App(
    '-title', 'Foo bar',
    '-width', 640,
    '-height', 480,
    '-depth', 32
);

app.loop = function() {
    var done = false;
    while(!done) {
	app.world.step();
	app.draw();
	done = app.handle_one_event();
    }
};
app.curr_event = new SDL.Event;

app.world = {
    rect: new SDL.Rect('-width', 10, '-height', 10, '-x', 320, '-y', -10),
    colr: new SDL.Color('-r', 0, '-g', 0, '-b', 255),
    toString: function () { return '' + this.rect + ' ' + this.colr; }
}

SDL.Rect.prototype.toString = function() {
    return '(' + this.x() + ',' + this.y() + ')';
}

SDL.Color.prototype.toString = function() {
    return '(' + this.r() + ',' + this.g() + ',' + this.b() + ')';
}

app.world.colr.randomize = function() {
    this.r(rand(256));
    this.g(rand(256));
    this.b(rand(256));
}

app.world.step = function() {
    var y = this.rect.y();
    if(y > 460) {
	y = -10;
	this.rect.x(rand(640));
	this.colr.randomize();
	Sys.say(''+this);
    }

    this.rect.y(y+10);
};

app.draw = function() {
    this.fill(this.world.rect, this.world.colr);
    this.update(this.world.rect);
    this.sync();
};

app.handle_one_event = function() {
    if(!this.curr_event.poll()) return false;
    if(this.curr_event.type() == SDL.SDL_QUIT()) return true;
    return false;
}

app.loop();
