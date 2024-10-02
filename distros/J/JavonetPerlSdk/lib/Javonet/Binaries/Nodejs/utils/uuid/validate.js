const REGEX = require('./REGEX');

function validate(uuid) {
  return typeof uuid === 'string' && REGEX.test(uuid);
}
module.exports = validate