love.graphics.setDefaultFilter('nearest', 'nearest')

function love.load()
    -- init something here ...
end

function love.update(dt)
    -- change some values based on your actions
end

function love.draw()
    -- draw your stuff here
    love.graphics.print('Welcome to the Love2d world!', 10, 10)
end

function love.resize(w, h)
    -- ...
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    end
end
